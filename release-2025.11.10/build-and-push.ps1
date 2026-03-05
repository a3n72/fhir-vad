# Docker 映像構建腳本
# 使用方式: .\build-and-push.ps1 [-Version <version>] [-ImageName <name>] [-Tag <tag>]

param(
    [string]$Version = "2025.11.10",
    [string]$ImageName = "hapi-fhir-jpaserver-starter",
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "=== HAPI FHIR JPA Server Starter - Docker 映像構建 ===" -ForegroundColor Green
Write-Host "版本: $Version" -ForegroundColor Cyan
Write-Host "映像名稱: $ImageName" -ForegroundColor Cyan
Write-Host "標籤: $Tag" -ForegroundColor Cyan
Write-Host ""

# 切換到專案根目錄（release 目錄的父目錄）
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$projectRoot\Dockerfile")) {
    Write-Host "錯誤：找不到 Dockerfile，請確認在正確的目錄執行腳本" -ForegroundColor Red
    exit 1
}
Set-Location $projectRoot
Write-Host "專案根目錄: $projectRoot" -ForegroundColor Cyan

# 構建映像
Write-Host "正在構建 Docker 映像..." -ForegroundColor Yellow
$imageTag = "${ImageName}:${Version}"
$latestTag = "${ImageName}:${Tag}"

Write-Host "構建標籤: $imageTag" -ForegroundColor Cyan
if ($Tag -ne $Version) {
    Write-Host "構建標籤: $latestTag" -ForegroundColor Cyan
}

# 構建映像（同時創建版本標籤和 latest 標籤）
if ($Tag -ne $Version) {
    docker build --target spring-boot -t $imageTag -t $latestTag .
} else {
    docker build --target spring-boot -t $imageTag .
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker 映像構建失敗！" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== 構建完成 ===" -ForegroundColor Green
Write-Host "映像標籤: $imageTag" -ForegroundColor Cyan
if ($Tag -ne $Version) {
    Write-Host "Latest 標籤: $latestTag" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "使用以下命令查看映像:" -ForegroundColor Yellow
Write-Host "  docker images | grep $ImageName" -ForegroundColor White
Write-Host ""
Write-Host "使用以下命令運行容器:" -ForegroundColor Yellow
Write-Host "  docker run -d -p 8080:8080 --name hapi-fhir $imageTag" -ForegroundColor White
