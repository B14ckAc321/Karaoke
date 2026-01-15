#!/bin/sh
set -e

# Use PORT env var if set (Railway), otherwise default to 80
# Railway sets PORT, but if it's 8080 (backend port), use 80 instead
if [ -z "$PORT" ] || [ "$PORT" = "8080" ]; then
    export PORT=80
fi

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
