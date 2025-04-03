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
COPY --from=build /tmp/hello-world .
CMD ["./hello-world"]
