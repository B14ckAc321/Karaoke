#!/bin/sh
set -e

# Use PORT env var if set (Railway), otherwise default to 80
export PORT=${PORT:-80}

# Generate nginx config with PORT env var
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Start backend in background
cd /app/backend
node dist/index.js &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Start nginx in foreground
exec nginx -g "daemon off;"
