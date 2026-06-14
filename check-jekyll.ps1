#requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$Urls = @(
    "http://127.0.0.1:4000/"
    "http://127.0.0.1:4000/?case=recommendation&template=blue&theme=ember"
    "http://127.0.0.1:4000/?case=admission&template=sidebar&theme=violet&lang=en"
    "http://127.0.0.1:4000/?case=postgraduate&template=timeline&theme=forest"
)

function Assert-DockerAvailable {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker CLI is not available in PATH. Install Docker Desktop first."
    }

    & docker version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Desktop is not running or the Docker daemon is unavailable."
    }

    & docker compose version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose is unavailable."
    }
}

Push-Location $ProjectRoot
try {
    Write-Host "Checking Docker..."
    Assert-DockerAvailable

    $containerId = @(& docker compose ps -q jekyll 2>$null | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
    if (-not $containerId) {
        throw "Compose service 'jekyll' was not found. Run .\start-jekyll.ps1 first."
    }

    $status = (& docker inspect --format "{{.State.Status}}" $containerId[0] 2>$null).Trim()
    if (-not $status) {
        throw "Unable to inspect the jekyll container."
    }

    Write-Host "Compose status:"
    & docker compose ps

    if ($status -ne "running") {
        throw "Compose service 'jekyll' is not running (status: $status)."
    }

    Write-Host ""
    Write-Host "HTTP checks:"
    foreach ($url in $Urls) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 10
        } catch {
            throw "Health check failed for $url. $($_.Exception.Message)"
        }

        if ($response.StatusCode -ne 200) {
            throw "Health check failed for $url. Expected 200, got $($response.StatusCode)."
        }

        Write-Host "  [200] $url"
    }

    Write-Host ""
    Write-Host "All checks passed."
} finally {
    Pop-Location
}
