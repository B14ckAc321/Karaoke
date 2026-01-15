# Karaoke Party System

A local-first karaoke scoring and selection system for parties with three distinct interfaces:
- **TV Display**: Shows proposed songs, scores, and countdown timer (full-screen, visually appealing)
- **DJ Control**: Manages scores (+1/+5/+10/custom, -1/-5), timer controls (start/stop/reset), and song management
- **Bar Control**: Manages scores only (no timer controls), accessible for bar staff

## Architecture

- **Backend**: Node.js (Express + Socket.IO) with SQLite database
- **Frontend**: Flutter web application
- **Deployment**: Docker Compose
- **Real-time**: Socket.IO for synchronized state across all devices

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 2GB of free disk space

### Launch the Entire System

1. **Clone or navigate to the project directory:**
   ```bash
   cd /path/to/Karaoke
   ```

2. **Start all services with Docker Compose:**
   ```bash
   docker-compose up --build
   ```

   This will:
   - Build the backend service (Node.js)
   - Build the frontend service (Flutter web)
   - Start both services
   - Create persistent volumes for data storage

3. **Access the application:**
   - **Frontend (Web UI)**: http://localhost:8081
   - **Backend API**: http://localhost:8082
   - **Backend Health Check**: http://localhost:8082/health

4. **Stop the system:**
   ```bash
   docker-compose down
   ```

   To also remove volumes (deletes all data):
   ```bash
   docker-compose down -v
   ```

### Running in Background

To run in detached mode:
```bash
docker-compose up -d --build
```

To view logs:
```bash
docker-compose logs -f
```

To stop:
```bash
docker-compose down
```

## Using the Application

### Accessing Different Interfaces

1. **Open the web app**: Navigate to http://localhost:8081 in your browser
2. **Select your role**:
   - **TV**: For the main display screen
   - **DJ**: For DJ booth controls
   - **Bar**: For bar staff controls

### Features

#### TV Screen
- Displays all proposed songs with their scores
- Shows countdown timer for song selection
- Full-screen, party-themed interface
- Customizable theme (colors, fonts, images)

#### DJ Interface
- View all songs with scores
- Add/remove points: -5, -1, +1, +5, +10, or custom amount
- Timer controls: Start, Stop, Reset
- Add new songs (title only - YouTube link auto-generated)
- Search songs by name
- Open YouTube links for karaoke videos
- Access settings for theme customization

#### Bar Interface
- View all songs with scores
- Add/remove points: -5, -1, +1, +5, +10, or custom amount
- Add new songs
- Access settings for theme customization
- No timer controls (DJ manages timing)

### Settings & Customization

Access the settings page from the DJ or Bar interface to customize:
- **Colors**: Primary, Secondary, Background, Card, Text, Accent (with color picker)
- **Fonts**: Font family (dropdown picker) and font sizes for titles, scores, timer
- **Images**: Upload background image and logo image

## API Documentation

### REST Endpoints

- `GET /health` - Health check
- `GET /state` - Get current state (songs and timer)
- `POST /songs` - Add a new song
  ```json
  { "title": "Song Name" }
  ```
- `DELETE /songs/:id` - Remove a song
- `POST /songs/:id/score` - Update song score
  ```json
  { "delta": 5 }  // or { "set": 10 }
  ```
- `POST /songs/:id/url` - Update YouTube URL
  ```json
  { "youtubeUrl": "https://youtube.com/..." }
  ```
- `POST /timer/start` - Start timer (optionally set duration)
  ```json
  { "durationSeconds": 60 }
  ```
- `POST /timer/stop` - Stop timer
- `POST /timer/reset` - Reset timer to duration
- `GET /theme` - Get theme settings
- `POST /theme` - Save theme settings
- `POST /upload/image` - Upload an image (multipart/form-data)
- `DELETE /images/:filename` - Delete an uploaded image
- `GET /images/:filename` - Get an uploaded image

### Socket.IO Events

**Server → Clients:**
- `state:update` - Broadcasts state changes to all connected clients
  ```json
  {
    "songs": [...],
    "timer": { "durationSeconds": 60, "remainingSeconds": 45, "isRunning": true }
  }
  ```

**Clients → Server:**
- `score:update` - Update a song's score
  ```json
  { "id": "song-id", "delta": 5 }
  ```
- `timer:control` - Control the timer
  ```json
  { "action": "start", "durationSeconds": 60 }
  ```

## Data Persistence

- **Database**: SQLite stored in Docker volume `karaoke_data`
- **Images**: Uploaded images stored in `/data/images` in the backend container
- **Theme Settings**: Stored in SQLite database

Data persists across container restarts. To reset everything, remove the volume:
```bash
docker-compose down -v
```

## Local Network Access

To access from other devices on your local network (tablets, phones, etc.):

1. **Find your host machine's IP address:**
   ```bash
   # Linux/Mac
   hostname -I
   # or
   ip addr show
   
   # Windows
   ipconfig
   ```

2. **Access from other devices:**
   - Frontend: `http://<YOUR_IP>:8081`
   - Backend: `http://<YOUR_IP>:8082`

3. **Ensure firewall allows connections on ports 8081 and 8082**

## Development

### Backend Development

```bash
cd backend
npm install
npm run dev  # Runs with nodemon for auto-reload
```

Backend runs on port 8080 by default (or 8082 when mapped in Docker).

### Frontend Development

```bash
cd karaoke
flutter pub get
flutter run -d chrome  # or your preferred device
```

The Flutter app will connect to `http://localhost:8082` for the backend.

### Building for Production

**Backend:**
```bash
cd backend
npm run build
```

**Frontend:**
```bash
cd karaoke
flutter build web --release
```

## Docker Services

- **backend**: Node.js Express server with Socket.IO
  - Port: 8082 (host) → 8080 (container)
  - Volume: `karaoke_data` for SQLite and images
  
- **frontend**: Flutter web app served by nginx
  - Port: 8081 (host) → 80 (container)
  - Depends on: backend

## Troubleshooting

### Port Already in Use

If ports 8081 or 8082 are already in use, modify `docker-compose.yml`:
```yaml
ports:
  - "8083:8080"  # Change host port
```

### Frontend Can't Connect to Backend

1. Ensure backend is running: `docker-compose ps`
2. Check backend logs: `docker-compose logs backend`
3. Verify backend health: `curl http://localhost:8082/health`
4. Check browser console for connection errors

### Database Issues

If you need to reset the database:
```bash
docker-compose down -v
docker-compose up --build
```

### Build Issues

If Docker build fails:
1. Clear Docker cache: `docker system prune -a`
2. Rebuild: `docker-compose build --no-cache`
3. Check logs: `docker-compose build 2>&1 | tee build.log`

## Project Structure

```
Karaoke/
├── backend/           # Node.js backend
│   ├── src/
│   │   ├── index.ts  # Express server + Socket.IO
│   │   └── db.ts     # SQLite database
│   └── Dockerfile
├── karaoke/          # Flutter frontend
│   ├── lib/
│   │   └── src/
│   │       ├── services/    # Backend communication
│   │       ├── repositories/# Data layer
│   │       ├── ui/          # UI pages (TV, DJ, Bar, Settings)
│   │       └── navigation/  # Routing
│   └── Dockerfile
├── docker-compose.yml
└── README.md
```

## License

Private project for party use.

## Notes

- State is synchronized in real-time across all connected devices
- Songs are automatically assigned IDs and default YouTube search links
- Theme customizations apply immediately to all interfaces
- All data persists in Docker volumes