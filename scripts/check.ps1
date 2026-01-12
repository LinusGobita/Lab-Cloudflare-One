# Pre-flight check for Cloudflare Zero Trust Lab (Windows PowerShell)

Write-Host "=== Cloudflare Zero Trust Lab - System Check ===" -ForegroundColor Cyan
Write-Host ""

$errors = 0

# Check Docker
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "✅ Docker installed: $dockerVersion" -ForegroundColor Green
    } else {
        throw
    }
} catch {
    Write-Host "❌ Docker not installed" -ForegroundColor Red
    $errors++
}

# Check Docker Compose
try {
    $composeVersion = docker compose version --short 2>$null
    if ($composeVersion) {
        Write-Host "✅ Docker Compose: $composeVersion" -ForegroundColor Green
    } else {
        throw
    }
} catch {
    Write-Host "❌ Docker Compose not available" -ForegroundColor Red
    $errors++
}

# Check Docker daemon
try {
    $null = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker daemon running" -ForegroundColor Green
    } else {
        throw
    }
} catch {
    Write-Host "❌ Docker daemon not running - please start Docker Desktop" -ForegroundColor Red
    $errors++
}

# Check internet
try {
    $response = Invoke-WebRequest -Uri "https://cloudflare.com" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Internet connection OK" -ForegroundColor Green
} catch {
    Write-Host "❌ No internet connection" -ForegroundColor Red
    $errors++
}

# Check .env file
Write-Host ""
if (Test-Path ".env") {
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match "your-token-here") {
        Write-Host "⚠️  .env exists but contains placeholder - add your token!" -ForegroundColor Yellow
    } else {
        Write-Host "✅ .env file configured" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  .env file missing - copy from .env.example" -ForegroundColor Yellow
}

Write-Host ""
if ($errors -eq 0) {
    Write-Host "=== All checks passed! Ready to start. ===" -ForegroundColor Green
} else {
    Write-Host "=== $errors error(s) found. Please fix before continuing. ===" -ForegroundColor Red
    exit 1
}
