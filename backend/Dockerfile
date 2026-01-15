FROM node:20-alpine AS deps
WORKDIR /app
# Build deps for native modules (better-sqlite3)
RUN apk add --no-cache python3 make g++
COPY package.json package-lock.json* .npmrc* ./
RUN npm install --no-audit --no-fund

FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules /app/node_modules
COPY tsconfig.json ./
COPY src ./src
RUN npx tsc -p tsconfig.json

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache libstdc++ wget
COPY --from=deps /app/node_modules /app/node_modules
COPY --from=build /app/dist /app/dist
COPY package.json ./
# Persistent data directory for sqlite
VOLUME ["/data"]
ENV DATA_DIR=/data
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=2s --retries=5 CMD wget -qO- http://localhost:8080/health || exit 1
CMD ["node", "dist/index.js"]

