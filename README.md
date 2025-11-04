## Karaoke Party System

Local-first karaoke scoring and selection system with three UIs:
- TV Display: shows proposed songs, scores, countdown timer.
- DJ Control: manages scores (+1/+5/+10/custom, -1/-5), timer start/stop/reset.
- Bar Control: manages scores only (no timer controls).

Backend: Node.js (Express + Socket.IO)
Frontend: Flutter (web + mobile/tablet). For now, docker serves `frontend_web/` as placeholder until Flutter is added.
Orchestration: Docker Compose

### Quick start

1) Build and run services:
```bash
docker compose up --build
```

2) Backend:
- Health: `http://localhost:8080/health`
- State: `http://localhost:8080/state`

3) Frontend placeholder:
- Static site: `http://localhost:8081/`

### API (REST) summary

- GET `/state` → current songs and timer
- POST `/songs` `{ id, title, artist? }` → add song
- DELETE `/songs/:id` → remove song
- POST `/songs/:id/score` `{ delta? , set? }` → update score
- POST `/timer/start` `{ durationSeconds? }` → start timer (optionally set duration)
- POST `/timer/stop` → stop timer
- POST `/timer/reset` → reset timer to duration

Real-time events via Socket.IO:
- Server → clients: `state:update` `{ songs: Song[], timer: TimerState }`
- Clients → server: `score:update` `{ id, delta?, set? }`
- Clients → server: `timer:control` `{ action: 'start'|'stop'|'reset', durationSeconds? }`

Types:
```ts
type Song = { id: string; title: string; artist?: string; score: number };
type TimerState = { durationSeconds: number; remainingSeconds: number; isRunning: boolean };
```

### Flutter plan

- Single Flutter app with role selection: `?role=tv|dj|bar` (or in-app switch with PIN)
- Shared Socket.IO client for state syncing
- TV route: full-screen list + large countdown (high visibility)
- DJ route: big accessible buttons: -5, -1, +1, +5, +10, +Custom; timer controls
- Bar route: same buttons without timer controls

### Local networking

- Tablets/phones on same LAN can access via host IP: `http://<HOST_IP>:8081` (frontend) and backend proxied inside compose network
- Backend reachable from frontend container by `http://backend:8080`

### Development

- Backend dev:
```bash
cd backend
npm install
npm run dev
```

- Compose:
```bash
docker compose up --build
```

### Notes

- State is in-memory; consider Redis if you need persistence.
- Add auth/PIN gate for DJ/Bar routes later.


