FROM golang:latest as builder

RUN echo "Building...."

COPY . /go/src/app
WORKDIR /go/src/app

RUN CGO_ENABLED=0 GO_ARCH=linux go build -o /bin/server .

FROM alpine:latest

COPY --from=builder /bin/server /bin/server

ENTRYPOINT [ "/bin/server" ]