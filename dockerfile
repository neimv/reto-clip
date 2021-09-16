FROM golang:1.16-alpine AS build_base

RUN apk add --no-cache git

WORKDIR /tmp/go-pet-app
COPY services/go.mod .
COPY services/go.sum .
RUN go mod download

COPY services/. .

RUN CGO_ENABLED=0 go test -v

RUN go build -o ./out/go-pet-app .

FROM alpine:latest

RUN apk add ca-certificates
COPY --from=build_base /tmp/go-pet-app/out/go-pet-app /app/go-pet-app

CMD [ "/app/go-pet-app" ]