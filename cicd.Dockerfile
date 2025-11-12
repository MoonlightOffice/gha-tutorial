# check=skip=SecretsUsedInArgOrEnv

### Set up necessary tools
FROM golang:latest AS base

# Install golangci-lint
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.6.1

# Copy only go.mod and go.sum first for better layer caching
ARG GITHUB_WORKSPACE
COPY ${GITHUB_WORKSPACE}/go.mod ${GITHUB_WORKSPACE}/go.sum /src/
WORKDIR /src

# Download dependencies with cache mount - this layer is cached unless go.mod/go.sum changes
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Now copy the rest of the source code
COPY ${GITHUB_WORKSPACE} /src

# Compile check with cache mounts for both module and build cache
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go vet ./...

ARG MESSAGE
RUN echo "Hello, $MESSAGE"


### Run jobs

# Run golang-ci lint with cache mounts
FROM base AS lint
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.cache/golangci-lint \
    golangci-lint run

# Test with cache mounts
FROM base AS test
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go test -v ./... -race

# Run gofumpt
FROM base AS format
RUN gofumpt -l . | diff -u /dev/null -

### Wait parallel execution

FROM base
COPY --from=lint /tmp /tmp
COPY --from=test /tmp /tmp
COPY --from=format /tmp /tmp

# docker buildx build -f cicd.Dockerfile --cache-from type=local,src=.cache/ --cache-to type=local,dest=.cache/,mode=max --build-arg GITHUB_WORKSPACE="." --output=type=cacheonly .