# First stage - build the provisioner
FROM golang:1.14-alpine3.11 as build
RUN apk add --update build-base

# Copy source tree
COPY vendor/ /app/vendor/
COPY go.mod go.sum /app/
COPY cmd/ /app/cmd/

# Build
WORKDIR /app
RUN go build -a -o cloudian-s3-operator ./cmd


# Final stage - distribution image
FROM alpine:3.11

COPY --from=build /app/cloudian-s3-operator /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/cloudian-s3-operator"]
CMD ["-v=2", "-alsologtostderr"]
