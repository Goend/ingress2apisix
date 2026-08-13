# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM node:22-alpine AS web
WORKDIR /src/web
COPY web/package.json web/package-lock.json ./
RUN npm ci
COPY web/ ./
RUN npm run build

FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS build
ARG TARGETOS
ARG TARGETARCH
ARG GOPROXY=https://goproxy.cn,direct
ENV GOPROXY=$GOPROXY
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=web /src/pkg/web/static/dist pkg/web/static/dist
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -buildvcs=false -o /out/ingress2apisix ./cmd/ingress2apisix

FROM alpine:3.20
RUN apk add --no-cache ca-certificates && adduser -D -u 10001 app
WORKDIR /home/app
COPY --from=build /out/ingress2apisix /usr/local/bin/ingress2apisix
COPY --from=build /src/转换示例文档-0827.md /home/app/docs/转换示例文档-0827.md
RUN chown -R app:app /home/app/docs
USER app
ENTRYPOINT ["ingress2apisix"]
