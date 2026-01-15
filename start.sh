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

# Test nginx configuration
echo "Testing nginx configuration..."
nginx -t || {
    echo "ERROR: Nginx configuration test failed!"
    cat /etc/nginx/nginx.conf
    exit 1
}

# Verify frontend files exist
echo "Checking frontend files..."
if [ ! -f /usr/share/nginx/html/index.html ]; then
    echo "ERROR: Frontend index.html not found!"
    ls -la /usr/share/nginx/html/ || echo "Directory doesn't exist!"
    exit 1
fi
echo "Frontend files found: $(ls /usr/share/nginx/html/ | head -5)"

# Start backend in background
cd /app/backend
echo "Starting backend on 127.0.0.1:3001..."
node dist/index.js &
BACKEND_PID=$!

# Wait a moment for backend to start
echo "Waiting for backend to be ready..."
sleep 3

# Verify backend is running
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "ERROR: Backend process died!"
    exit 1
fi

# Start nginx in foreground
echo "Starting nginx on port $PORT..."
exec nginx -g "daemon off;"
