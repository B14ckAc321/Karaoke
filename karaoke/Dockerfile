# Build Flutter web
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml ./
RUN flutter create . --platforms web
RUN flutter pub get
COPY lib ./lib
COPY web ./web
RUN flutter build web --release --no-tree-shake-icons --pwa-strategy=none -v

# Serve with nginx
FROM nginx:1.27-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
