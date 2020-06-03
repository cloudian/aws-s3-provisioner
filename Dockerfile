# First stage - build the provisioner
FROM golang:1.14-alpine3.11 as build
RUN apk add --update build-base

# Copy source tree
COPY vendor/ /app/vendor/
COPY go.mod go.sum /app/
COPY cmd/ /app/cmd/

# Build
WORKDIR /app
RUN go build -a -o aws-s3-provisioner ./cmd


# Final stage - distribution image
FROM alpine:3.11

COPY --from=build /app/aws-s3-provisioner /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/aws-s3-provisioner"]
CMD ["-v=2", "-alsologtostderr"]
