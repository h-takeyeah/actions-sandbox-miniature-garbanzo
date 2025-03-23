# syntax=docker/dockerfile:1
FROM golang AS build
WORKDIR /usr/src/app

COPY <<EOF /usr/src/app/main.go
package main

import "fmt"

func main() {
	fmt.Println("Hello world! This is Container :)")
}
EOF

RUN go build -v -o /tmp/hello-world main.go

FROM scratch
LABEL org.opencontainers.image.source=https://github.com/h-takeyeah/actions-sandbox-miniature-garbanzo
LABEL org.opencontainers.image.description="hello world image"
LABEL org.opencontainers.image.licenses=MIT
COPY --from=build /tmp/hello-world .
CMD ["./hello-world"]
