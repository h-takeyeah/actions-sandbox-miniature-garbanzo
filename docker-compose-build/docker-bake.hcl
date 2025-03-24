services:
  docker-metadata-action: &meta {}
  hello-world:
    << : *meta
    build: .

