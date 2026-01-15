# Deploying to Railway

This guide will help you deploy the Karaoke app to Railway.

## Prerequisites

1. A Railway account (sign up at [railway.app](https://railway.app))
2. GitHub account (to connect your repository)

## Deployment Steps

### 1. Push your code to GitHub

Make sure your code is pushed to a GitHub repository.

### 2. Create a new Railway project

1. Go to [railway.app](https://railway.app)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose your repository

### 3. Configure the service

Railway will automatically detect the `Dockerfile` in the root directory and use it.

### 4. Set environment variables

In Railway dashboard, go to your service → Variables tab, and add:

- `NODE_ENV=production`
- `DATA_DIR=/data`

### 5. Add persistent storage (IMPORTANT!)

**This is required for the database to work!**

1. Go to your service → Settings
2. Click on **"Volumes"** tab
3. Click **"+ New Volume"**
4. Set the mount path to: `/data`
5. Give it a name (e.g., `karaoke-data`)
6. This will persist your SQLite database and uploaded images

**Without this volume, your database will be lost on every deployment!**

### 6. Deploy

Railway will automatically build and deploy. The build process will:
- Build the Node.js backend
- Build the Flutter web frontend
- Combine both into a single container
- Start both services (backend on port 8080, nginx on port 80)

### 7. Get your URL

Once deployed, Railway will provide you with a public URL (e.g., `https://your-app.railway.app`).

## How it works

The combined Dockerfile:
- Builds the backend (Node.js + Express + Socket.IO)
- Builds the frontend (Flutter web)
- Runs both in one container:
  - Backend listens on `localhost:8080`
  - Nginx serves the frontend and proxies API requests to the backend
  - All requests go through port 80 (or Railway's assigned PORT)

## Troubleshooting

### Build fails

- Check that all files are committed to GitHub
- Ensure `karaoke/assets/fonts` and `karaoke/assets/images` directories exist (run `fix-assets.sh` locally first)

### App doesn't connect

- Check Railway logs for errors
- Verify environment variables are set
- Ensure the volume is mounted at `/data`

### Socket.IO not working

- Check that the nginx proxy configuration is correct
- Verify WebSocket upgrade headers are being passed

## Notes

- Railway's free tier includes $5/month credit
- The app uses persistent storage for the database and images
- All API routes are proxied through nginx to the backend
- Socket.IO connections are properly proxied for real-time updates
