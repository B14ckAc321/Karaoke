#!/bin/bash
# Fix assets directory for Docker build
# Run this if you get "/assets": not found error

cd "$(dirname "$0")/karaoke" || exit 1
mkdir -p assets/fonts assets/images
touch assets/fonts/.gitkeep assets/images/.gitkeep
echo "Assets directory structure created successfully!"
echo "You can now run: docker-compose build --no-cache frontend"
