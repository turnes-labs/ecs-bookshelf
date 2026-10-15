# --- build the Go application ---
FROM golang:1.27 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o book ./cmd/api

# --- final minimal runtime ---
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /app/book /book

USER nonroot:nonroot

ENTRYPOINT ["/book"]
