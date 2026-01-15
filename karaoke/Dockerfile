# Build Flutter web
FROM instrumentisto/flutter:latest AS build
WORKDIR /app

# Copy dependency files first for better caching
COPY pubspec.yaml pubspec.lock* ./
COPY l10n.yaml ./

# Copy lib directory (needed for l10n generation during pub get)
COPY lib ./lib

# Create Flutter project structure and get dependencies
RUN flutter create . --platforms web
RUN flutter pub get
COPY web ./web
COPY assets ./assets

# Build Flutter web app
RUN flutter build web --release --no-tree-shake-icons --pwa-strategy=none

# Serve with nginx
FROM nginx:1.27-alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# Add nginx configuration for SPA routing
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # SPA routing - serve index.html for all routes \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    \
    # Cache static assets \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
