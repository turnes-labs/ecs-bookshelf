package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"maps"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"
	"uuid" // Go 1.27+
)

// shutdownTimeout is how long in-flight requests get to finish after
// SIGTERM. It must stay below the ECS task's stopTimeout (30s by default),
// or ECS sends SIGKILL before the server is done.
const shutdownTimeout = 20 * time.Second

var (
	// mu guards books: net/http serves each request on its own goroutine.
	mu    sync.RWMutex
	books map[string]Book = map[string]Book{}
)

type Book struct {
	Id     string `json:"id"`
	Title  string `json:"title"`
	Author string `json:"author"`
}

type UpdateBookPayload struct {
	Title  *string `json:"title,omitempty"`
	Author *string `json:"author,omitempty"`
}

func UpdateBook(target *Book, input UpdateBookPayload) {
	if input.Title != nil {
		target.Title = *input.Title
	}
	if input.Author != nil {
		target.Author = *input.Author
	}
}

type Healthz struct {
	Status   string `json:"status,omitempty"`
	Database string `json:"db,omitempty"`
}

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /books", func(w http.ResponseWriter, r *http.Request) {
		// Copy under the lock so encoding doesn't race with writers.
		mu.RLock()
		snapshot := maps.Clone(books)
		mu.RUnlock()

		WriteData(w, http.StatusOK, snapshot)
	})

	mux.HandleFunc("GET /books/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")
		mu.RLock()
		book, ok := books[id]
		mu.RUnlock()
		if !ok {
			WriteError(w, http.StatusNotFound, "Book not found", nil)
			return
		}

		WriteData(w, http.StatusOK, book)
	})

	mux.HandleFunc("POST /books", func(w http.ResponseWriter, r *http.Request) {
		newID := uuid.NewV7().String()

		var newBook Book
		err := DecodeBody(r.Body, &newBook)

		if err != nil {
			WriteError(w, http.StatusBadRequest, "Invalid JSON payload format", err)
			return
		}

		if newBook.Title == "" || newBook.Author == "" {
			WriteError(w, http.StatusUnprocessableEntity, "Title and Author fields are strictly required", nil)
			return
		}

		newBook.Id = newID

		mu.Lock()
		books[newID] = newBook
		mu.Unlock()

		WriteData(w, http.StatusCreated, newBook)

	})

	mux.HandleFunc("PUT /books/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")

		// Decode before taking the lock so a slow client doesn't block others.
		var updateBook UpdateBookPayload
		err := DecodeBody(r.Body, &updateBook)

		if err != nil {
			WriteError(w, http.StatusBadRequest, "Invalid JSON payload format", err)
			return
		}

		// Read, update and store under one lock so concurrent updates
		// to the same book can't overwrite each other.
		mu.Lock()
		book, ok := books[id]
		if !ok {
			mu.Unlock()
			WriteError(w, http.StatusNotFound, "Book not found", nil)
			return
		}

		UpdateBook(&book, updateBook)

		books[id] = book
		mu.Unlock()

		message := "Book " + id + " - " + book.Title + " updated"
		WriteSuccess(w, http.StatusOK, message)

	})

	mux.HandleFunc("DELETE /books/{id}", func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")
		mu.Lock()
		book, ok := books[id]
		if ok {
			delete(books, id)
		}
		mu.Unlock()
		if !ok {
			WriteError(w, http.StatusNotFound, "Book not found", nil)
			return
		}

		message := "Book " + id + " - " + book.Title + " deleted"
		WriteSuccess(w, http.StatusOK, message)

	})

	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		healthz := Healthz{
			Status:   "OK",
			Database: "in memory",
		}
		WriteData(w, http.StatusOK, healthz)
	})

	srv := &http.Server{
		Addr:              ":8080",
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	// ECS sends SIGTERM when it stops a task; SIGINT covers Ctrl+C locally.
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	serverErr := make(chan error, 1)
	go func() {
		slog.Info("server listening", "addr", srv.Addr)
		serverErr <- srv.ListenAndServe()
	}()

	select {
	case err := <-serverErr:
		// The server failed to start or crashed (e.g. port already in use).
		slog.Error("server failed", "error", err)
		os.Exit(1)
	case <-ctx.Done():
		stop() // a second signal now kills the process immediately
		slog.Info("shutdown signal received, draining connections")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	// Shutdown stops accepting new connections and waits for in-flight
	// requests to finish, up to shutdownTimeout.
	if err := srv.Shutdown(shutdownCtx); err != nil {
		slog.Error("graceful shutdown failed", "error", err)
		os.Exit(1)
	}

	if err := <-serverErr; !errors.Is(err, http.ErrServerClosed) {
		slog.Error("server stopped with error", "error", err)
		os.Exit(1)
	}

	slog.Info("server stopped")
}

// APIResponse establishes a predictable structure for every API response.
type APIResponse[T any] struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	Data    T      `json:"data,omitempty"`
	Error   string `json:"error,omitempty"`
}

// generic helper that decodes an io.ReadCloser to any pointer type.
func DecodeBody[T any](body io.ReadCloser, target *T) error {
	if body == nil {
		return fmt.Errorf("response body is nil")
	}
	defer body.Close()

	if err := json.NewDecoder(body).Decode(target); err != nil {
		return fmt.Errorf("json decode error: %w", err)
	}
	return nil
}

func WriteJSON[T any](w http.ResponseWriter, status int, data T) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func WriteData[T any](w http.ResponseWriter, status int, data T) {
	response := APIResponse[T]{
		Success: true,
		Data:    data,
	}
	WriteJSON(w, status, response)
}

func WriteError(w http.ResponseWriter, status int, userMessage string, internalErr error) {
	errString := ""
	if internalErr != nil {
		errString = internalErr.Error()
	}

	response := APIResponse[any]{
		Success: false,
		Message: userMessage,
		Error:   errString,
	}

	WriteJSON(w, status, response)
}

func WriteSuccess(w http.ResponseWriter, status int, message string) {
	response := APIResponse[any]{
		Success: true,
		Message: message,
	}
	WriteJSON(w, status, response)
}
