#!/bin/bash
# Pre-flight check for Cloudflare Zero Trust Lab

echo "=== Cloudflare Zero Trust Lab - System Check ==="
echo ""

ERRORS=0

# Check Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker installed: $(docker --version | cut -d' ' -f3 | tr -d ',')"
else
    echo "❌ Docker not installed"
    ERRORS=$((ERRORS+1))
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    echo "✅ Docker Compose: $(docker compose version --short)"
else
    echo "❌ Docker Compose not available"
    ERRORS=$((ERRORS+1))
fi

# Check Docker daemon
if docker info &> /dev/null 2>&1; then
    echo "✅ Docker daemon running"
else
    echo "❌ Docker daemon not running - please start Docker Desktop"
    ERRORS=$((ERRORS+1))
fi

# Check internet
if curl -s --max-time 5 https://cloudflare.com > /dev/null; then
    echo "✅ Internet connection OK"
else
    echo "❌ No internet connection"
    ERRORS=$((ERRORS+1))
fi

# Check .env file
echo ""
if [ -f .env ]; then
    if grep -q "your-token-here" .env; then
        echo "⚠️  .env exists but contains placeholder - add your token!"
    else
        echo "✅ .env file configured"
    fi
else
    echo "⚠️  .env file missing - copy from .env.example"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "=== All checks passed! Ready to start. ==="
else
    echo "=== $ERRORS error(s) found. Please fix before continuing. ==="
    exit 1
fi
