# 將 TWPAS 的 package.tgz 解壓到 igs\<Version>\package
# 用法：.\igs\extract_pas_package.ps1 -TgzPath ".\path\to\package.tgz" -Version "pas-1.1.1"
# 或：  .\igs\extract_pas_package.ps1 -TgzPath ".\package.tgz" -Version "pas-1.2.1"

param(
    [Parameter(Mandatory = $true)]
    [string] $TgzPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet("pas-1.1.1", "pas-1.2.1")]
    [string] $Version
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

$tgzFull = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TgzPath)
if (-not (Test-Path -LiteralPath $tgzFull)) {
    Write-Error "找不到檔案: $TgzPath"
}

$targetBase = Join-Path $projectRoot "igs" $Version
$targetPackage = Join-Path $targetBase "package"

$tempDir = Join-Path $env:TEMP "fhir-ig-extract-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    Write-Host "解壓 $TgzPath -> 暫存目錄..."
    & tar -xzf $tgzFull -C $tempDir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        # 若 tar 不支援 -C，改在 tempDir 內解壓
        Set-Location $tempDir
        & tar -xzf $tgzFull 2>&1 | Out-Null
        Set-Location $projectRoot
    }

    $tarFile = Join-Path $tempDir "package.tar"
    $innerPackage = Join-Path $tempDir "package"

    if (Test-Path -LiteralPath $tarFile) {
        Write-Host "再解壓 package.tar..."
        & tar -xf $tarFile -C $tempDir 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Set-Location $tempDir
            & tar -xf $tarFile 2>&1 | Out-Null
            Set-Location $projectRoot
        }
    }

    if (-not (Test-Path -LiteralPath $innerPackage)) {
        Write-Error "解壓後未找到 package 資料夾，請檢查 package.tgz 內容（應為 package.tar 或內含 package 目錄）。"
    }

    New-Item -ItemType Directory -Path $targetBase -Force | Out-Null
    if (Test-Path -LiteralPath $targetPackage) {
        Remove-Item -Recurse -Force -LiteralPath $targetPackage
    }
    Move-Item -LiteralPath $innerPackage -Destination $targetPackage -Force
    Write-Host "完成：已放置至 $targetPackage"
}
finally {
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -Recurse -Force -LiteralPath $tempDir
    }
}
