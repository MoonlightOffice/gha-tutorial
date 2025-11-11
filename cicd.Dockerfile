# check=skip=SecretsUsedInArgOrEnv

### Set up necessary tools
FROM golang:latest AS base

# Install golangci-lint
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.6.1

# Copy git repository
ARG GITHUB_WORKSPACE
COPY ${GITHUB_WORKSPACE} /src
WORKDIR /src

# Compile check & cache modules
RUN go vet ./...

### Run jobs

# Run golang-ci lint 
FROM base
RUN golangci-lint run

# Test
FROM base
RUN go test -v ./... -race

# Run gofumpt
FROM base
RUN gofumpt -l . | diff -u /dev/null -
