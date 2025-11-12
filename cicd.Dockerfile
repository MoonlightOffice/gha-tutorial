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

ARG MESSAGE
RUN echo "Hello, $MESSAGE"


### Run jobs

# Run golang-ci lint 
FROM base AS lint
RUN golangci-lint run

# Test
FROM base AS test
RUN go test -v ./... -race

# Run gofumpt
FROM base AS format
RUN gofumpt -l . | diff -u /dev/null -

### Wait parallel exeecution

FROM base
COPY --from=lint /tmp /tmp
COPY --from=test /tmp /tmp
COPY --from=format /tmp /tmp

# docker buildx build -f cicd.Dockerfile --cache-from type=local,src=.cache/ --cache-to type=local,dest=.cache/,mode=max --build-arg GITHUB_WORKSPACE="." --output=type=cacheonly .