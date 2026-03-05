#!/bin/bash
# Docker 映像構建腳本
# 使用方式: ./build-and-push.sh [version] [image-name] [tag]

set -e

VERSION="${1:-2025.11.10}"
IMAGE_NAME="${2:-hapi-fhir-jpaserver-starter}"
TAG="${3:-latest}"

echo "=== HAPI FHIR JPA Server Starter - Docker 映像構建 ==="
echo "版本: $VERSION"
echo "映像名稱: $IMAGE_NAME"
echo "標籤: $TAG"
echo ""

# 切換到專案根目錄（release 目錄的父目錄）
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
    echo "錯誤：找不到 Dockerfile，請確認在正確的目錄執行腳本"
    exit 1
fi
cd "$PROJECT_ROOT"
echo "專案根目錄: $PROJECT_ROOT"

# 構建映像
echo "正在構建 Docker 映像..."
IMAGE_TAG="${IMAGE_NAME}:${VERSION}"
LATEST_TAG="${IMAGE_NAME}:${TAG}"

echo "構建標籤: $IMAGE_TAG"
if [ "$TAG" != "$VERSION" ]; then
    echo "構建標籤: $LATEST_TAG"
fi

# 構建映像（同時創建版本標籤和 latest 標籤）
if [ "$TAG" != "$VERSION" ]; then
    docker build --target spring-boot -t "$IMAGE_TAG" -t "$LATEST_TAG" .
else
    docker build --target spring-boot -t "$IMAGE_TAG" .
fi

echo ""
echo "=== 構建完成 ==="
echo "映像標籤: $IMAGE_TAG"
if [ "$TAG" != "$VERSION" ]; then
    echo "Latest 標籤: $LATEST_TAG"
fi
echo ""
echo "使用以下命令查看映像:"
echo "  docker images | grep $IMAGE_NAME"
echo ""
echo "使用以下命令運行容器:"
echo "  docker run -d -p 8080:8080 --name hapi-fhir $IMAGE_TAG"
