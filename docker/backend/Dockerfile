FROM golang:1.26 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -o /app .

FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
