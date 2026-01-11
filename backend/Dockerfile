# Build stage
FROM golang:1.25.5-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache gcc musl-dev

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o chat-server main.go

# Runtime stage
FROM alpine:3.19

WORKDIR /app

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /app/chat-server .

# Copy migrations (needed for database setup)
COPY --from=builder /app/migrations ./migrations

# Expose port
EXPOSE 8080

# Run the application
CMD ["./chat-server"]
