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

function Resolve-Tool {
    param(
        [string[]] $Candidates,
        [string] $Label
    )

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    foreach ($candidate in $Candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            if ($command.Source) { return $command.Source }
            if ($command.Path) { return $command.Path }
            return $command.Name
        }
    }

    throw "$Label is not available. Install Docker Desktop first."
}

$DockerExe = Resolve-Tool @(
    "$env:ProgramFiles\Docker\Docker\Docker\resources\bin\docker.exe"
    "docker"
) "Docker CLI"

$ComposeExe = Resolve-Tool @(
    "$env:ProgramFiles\Docker\Docker\cli-plugins\docker-compose.exe"
    "docker-compose"
) "Docker Compose"

function Assert-DockerAvailable {
    & $DockerExe version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Desktop is not running or the Docker daemon is unavailable."
    }
    & $ComposeExe version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose is unavailable."
    }
}

function Wait-ForHttp200 {
    param(
        [string] $Url,
        [int] $TimeoutSeconds = 90
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastError = ""

    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                return $response
            }

            $lastError = "Expected 200, got $($response.StatusCode)."
        } catch {
            $lastError = $_.Exception.Message
        }

        Start-Sleep -Seconds 3
    }

    throw "Health check failed for $Url. $lastError"
}

Push-Location $ProjectRoot
try {
    Write-Host "Checking Docker..."
    Assert-DockerAvailable

    $containerId = @(& $ComposeExe ps -q jekyll 2>$null | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
    if (-not $containerId) {
        throw "Compose service 'jekyll' was not found. Run .\start-jekyll.ps1 first."
    }

    $status = (& $DockerExe inspect --format "{{.State.Status}}" $containerId[0] 2>$null).Trim()
    if (-not $status) {
        throw "Unable to inspect the jekyll container."
    }

    Write-Host "Compose status:"
    & $ComposeExe ps

    if ($status -ne "running") {
        throw "Compose service 'jekyll' is not running (status: $status)."
    }

    Write-Host ""
    Write-Host "HTTP checks:"
    foreach ($url in $Urls) {
        $response = Wait-ForHttp200 -Url $url
        Write-Host "  [200] $url"
    }

    Write-Host ""
    Write-Host "All checks passed."
} finally {
    Pop-Location
}
