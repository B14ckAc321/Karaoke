# Multi-stage build for combined backend + frontend

# ============================================
# Stage 1: Build Backend
# ============================================
FROM node:20-alpine AS backend-deps
WORKDIR /app/backend
RUN apk add --no-cache python3 make g++
COPY backend/package.json backend/package-lock.json* ./
RUN npm install --no-audit --no-fund

FROM node:20-alpine AS backend-build
WORKDIR /app/backend
COPY --from=backend-deps /app/backend/node_modules ./node_modules
COPY backend/tsconfig.json ./
COPY backend/src ./src
RUN npx tsc -p tsconfig.json

# ============================================
# Stage 2: Build Frontend
# ============================================
FROM instrumentisto/flutter:latest AS frontend-build
WORKDIR /app/frontend

# Copy dependency files
COPY karaoke/pubspec.yaml karaoke/pubspec.lock* ./
COPY karaoke/l10n.yaml ./

# Copy lib directory (needed for l10n generation)
COPY karaoke/lib ./lib

# Create Flutter project and get dependencies
RUN flutter create . --platforms web
RUN flutter pub get

# Copy web and assets
COPY karaoke/web ./web
RUN mkdir -p assets/fonts assets/images
COPY karaoke/assets ./assets

# Build Flutter web app
RUN flutter build web --release --no-tree-shake-icons --pwa-strategy=none

# ============================================
# Stage 3: Final Runtime Image
# ============================================
FROM node:20-alpine

# Install nginx and build dependencies (for rebuilding native modules if needed)
RUN apk add --no-cache nginx python3 make g++ libstdc++ wget dumb-init gettext && \
    mkdir -p /var/log/nginx /var/cache/nginx /etc/nginx/conf.d

# Copy backend files
WORKDIR /app/backend
COPY --from=backend-deps /app/backend/node_modules ./node_modules
COPY --from=backend-build /app/backend/dist ./dist
COPY backend/package.json ./

# Rebuild native modules for the runtime environment
RUN npm rebuild better-sqlite3 --build-from-source

# Copy frontend files
COPY --from=frontend-build /app/frontend/build/web /usr/share/nginx/html

# Create nginx config template (will be processed at runtime with PORT env var)
RUN echo 'server { \
    listen $PORT; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # Proxy Socket.IO requests first \
    location /socket.io { \
        proxy_pass http://localhost:8080; \
        proxy_http_version 1.1; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
    \
    # Proxy backend API routes (songs, state, health, theme, upload, images) \
    location ~ ^/(songs|state|health|theme|upload|images) { \
        proxy_pass http://localhost:8080; \
        proxy_http_version 1.1; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
    \
    # Cache static assets \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
    \
    # SPA routing - serve index.html for all other routes \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf.template

# Copy and set up startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Persistent data directory (Railway volumes are configured in dashboard, not Dockerfile)
ENV NODE_ENV=production
ENV DATA_DIR=/data

EXPOSE 80

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["/start.sh"]
