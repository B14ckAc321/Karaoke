#!/bin/bash

# Karaoke Party System - Quick Start Script

echo "🎤 Starting Karaoke Party System..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Error: docker-compose is not installed."
    exit 1
fi

# Use docker compose (newer) or docker-compose (older)
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "📦 Building and starting services..."
$COMPOSE_CMD up --build -d

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Services started successfully!"
    echo ""
    echo "🌐 Access the application:"
    echo "   Frontend: http://localhost:8081"
    echo "   Backend:  http://localhost:8082"
    echo ""
    echo "📊 View logs: $COMPOSE_CMD logs -f"
    echo "🛑 Stop services: $COMPOSE_CMD down"
    echo ""
else
    echo ""
    echo "❌ Failed to start services. Check the logs:"
    echo "   $COMPOSE_CMD logs"
    exit 1
fi
