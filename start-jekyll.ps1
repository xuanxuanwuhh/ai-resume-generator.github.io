#requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ProjectRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$SiteUrl = "http://127.0.0.1:4000/"
$ExampleUrls = @(
    "http://127.0.0.1:4000/?case=recommendation&template=blue&theme=ember"
    "http://127.0.0.1:4000/?case=admission&template=sidebar&theme=violet&lang=en"
    "http://127.0.0.1:4000/?case=postgraduate&template=timeline&theme=forest"
)

function Normalize-Path {
    param(
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }

    try {
        $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    } catch {
        $resolved = $Path
    }

    return $resolved.TrimEnd('\').ToLowerInvariant()
}

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

function Remove-ProjectContainers {
    $normalizedProjectRoot = Normalize-Path $ProjectRoot

    Write-Host "Stopping compose services for this project..."
    & docker compose down --remove-orphans
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to stop existing compose services."
    }

    $containerIds = @(& docker ps -aq 2>$null)
    if (-not $containerIds) {
        return
    }

    foreach ($containerId in $containerIds) {
        if ([string]::IsNullOrWhiteSpace($containerId)) {
            continue
        }

        $inspectJson = & docker inspect $containerId 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $inspectJson) {
            continue
        }

        $inspectResult = (($inspectJson | Out-String) | ConvertFrom-Json)
        if (-not $inspectResult) {
            continue
        }

        $container = $inspectResult[0]
        $matchesProject = $false

        foreach ($mount in @($container.Mounts)) {
            if ($mount.Destination -ne "/srv/jekyll") {
                continue
            }

            if ((Normalize-Path $mount.Source) -eq $normalizedProjectRoot) {
                $matchesProject = $true
                break
            }
        }

        if (-not $matchesProject) {
            continue
        }

        $name = $container.Name.TrimStart('/')
        Write-Host "Removing leftover container $name..."
        & docker rm -f $containerId | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to remove container $name ($containerId)."
        }
    }
}

function Get-ListenerRows {
    $listeners = @(Get-NetTCPConnection -LocalPort 4000 -State Listen -ErrorAction SilentlyContinue | Sort-Object OwningProcess -Unique)

    $rows = @(
        foreach ($listener in $listeners) {
        $process = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue

        [pscustomobject]@{
            LocalAddress = $listener.LocalAddress
            LocalPort = $listener.LocalPort
            ProcessId = $listener.OwningProcess
            ProcessName = if ($process) { $process.ProcessName } else { "Unknown" }
            Path = if ($process) { $process.Path } else { "" }
        }
        }
    )

    return $rows
}

function Assert-Port4000Available {
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $dockerConflicts = @(& docker ps --filter "publish=4000" --format "{{.ID}}|{{.Image}}|{{.Names}}|{{.Ports}}" 2>$null | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($dockerConflicts.Count -gt 0) {
            $details = $dockerConflicts -join [Environment]::NewLine
            throw "Port 4000 is already published by another Docker container.`n$details"
        }

        $listenerRows = @(Get-ListenerRows)
        if ($listenerRows.Count -eq 0) {
            return
        }

        $processNames = @($listenerRows | Select-Object -ExpandProperty ProcessName -Unique)
        if ($processNames.Count -eq 1 -and $processNames[0] -eq "com.docker.backend" -and $attempt -lt 5) {
            Start-Sleep -Seconds 2
            continue
        }

        $table = $listenerRows | Format-Table -AutoSize | Out-String
        throw "Port 4000 is already in use by a non-project process.`n$table"
    }

    throw "Port 4000 did not become available after stopping project containers."
}

function Reset-SiteOutput {
    $sitePath = Join-Path $ProjectRoot "_site"
    if (Test-Path -LiteralPath $sitePath) {
        Write-Host "Removing existing _site output..."
        Remove-Item -LiteralPath $sitePath -Recurse -Force
    }
}

function Wait-ForSite {
    $deadline = (Get-Date).AddSeconds(180)

    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $SiteUrl -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                return
            }
        } catch {
        }

        Start-Sleep -Seconds 2
    }

    $logs = @(& docker compose logs --tail 80 jekyll 2>&1)
    $message = ($logs -join [Environment]::NewLine)
    throw "Jekyll did not become ready within 180 seconds.`n$message"
}

Push-Location $ProjectRoot
try {
    Write-Host "Checking Docker..."
    Assert-DockerAvailable

    Remove-ProjectContainers
    Assert-Port4000Available
    Reset-SiteOutput

    Write-Host "Starting Jekyll with docker compose..."
    & docker compose up -d
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start docker compose service."
    }

    Write-Host "Waiting for Jekyll to respond..."
    Wait-ForSite

    Write-Host ""
    Write-Host "Jekyll is ready."
    Write-Host "Home: $SiteUrl"
    Write-Host "Examples:"
    foreach ($url in $ExampleUrls) {
        Write-Host "  $url"
    }
} finally {
    Pop-Location
}
