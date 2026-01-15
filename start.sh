#!/bin/sh
set -e

# Use PORT env var if set (Railway), otherwise default to 80
# Railway automatically sets PORT to the port it wants the service to listen on
export PORT=${PORT:-80}

# Debug: print PORT value
echo "Starting with PORT=$PORT"

# Generate nginx config with PORT env var
envsubst '$PORT' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Debug: verify substitution worked
echo "Nginx config generated, listening on port:"
grep "listen" /etc/nginx/nginx.conf | head -1

# Start backend in background
cd /app/backend
node dist/index.js &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Start nginx in foreground
exec nginx -g "daemon off;"
