import express from 'express';
import http from 'http';
import cors from 'cors';
import helmet from 'helmet';
import { Server } from 'socket.io';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { getAllSongs, insertSong, deleteSong as dbDeleteSong, updateScore as dbUpdateScore, updateYoutubeUrl, DbSong, getThemeSetting, setThemeSetting, getAllThemeSettings } from './db';
import crypto from 'crypto';

type Song = {
  id: string;
  title: string;
  artist?: string;
  score: number;
  youtubeUrl?: string;
};

type TimerState = {
  durationSeconds: number;
  remainingSeconds: number;
  isRunning: boolean;
  lastTickTs?: number; // epoch ms for drift correction
};

type AppState = {
  songs: Song[];
  timer: TimerState;
};

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*'}
});

app.use(express.json());
app.use(cors());
app.use(helmet({
  crossOriginResourcePolicy: false,
  crossOriginOpenerPolicy: false,
  crossOriginEmbedderPolicy: false,
}));

// Image upload setup
const dataDir = process.env.DATA_DIR || '/data';
const imagesDir = path.join(dataDir, 'images');
if (!fs.existsSync(imagesDir)) fs.mkdirSync(imagesDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, imagesDir),
  filename: (_req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`),
});
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

// Serve uploaded images
app.use('/images', express.static(imagesDir));

const defaultState: AppState = {
  songs: [],
  timer: { durationSeconds: 60, remainingSeconds: 60, isRunning: false },
};

let state: AppState = structuredClone(defaultState);
// initialize songs from DB (already sorted by score DESC from DB)
try {
  const dbSongs = getAllSongs();
  console.log(`Loaded ${dbSongs.length} songs from database`);
  state.songs = dbSongs.map((s: DbSong) => ({ id: s.id, title: s.title, artist: s.artist ?? undefined, score: s.score, youtubeUrl: s.youtubeUrl ?? undefined }));
} catch (error) {
  console.error('Error loading songs from database:', error);
  state.songs = [];
}

function sortSongsByScore() {
  state.songs.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return (a.title || '').localeCompare(b.title || '', undefined, { sensitivity: 'base' });
  });
}

function broadcastState() {
  sortSongsByScore();
  io.emit('state:update', state);
}

function broadcastThemeUpdate() {
  io.emit('theme:update', getAllThemeSettings());
}

function recalcRemaining() {
  if (!state.timer.isRunning || !state.timer.lastTickTs) return;
  const now = Date.now();
  const elapsed = Math.floor((now - state.timer.lastTickTs) / 1000);
  if (elapsed > 0) {
    state.timer.remainingSeconds = Math.max(0, state.timer.remainingSeconds - elapsed);
    state.timer.lastTickTs = now;
    if (state.timer.remainingSeconds === 0) {
      state.timer.isRunning = false;
      state.timer.lastTickTs = undefined;
    }
  }
}

// REST API
app.get('/health', (_req, res) => res.json({ ok: true }));

app.get('/state', (_req, res) => {
  recalcRemaining();
  res.json(state);
});

app.get('/songs', (_req, res) => {
  res.json(getAllSongs());
});

app.post('/songs', (req, res) => {
  let { id, title, artist, youtubeUrl } = req.body ?? {};
  if (!title) return res.status(400).json({ error: 'title required' });
  if (!id) id = crypto.randomUUID();
  const existing = state.songs.find(s => s.id === id);
  if (existing) return res.status(409).json({ error: 'song id exists' });
  if (!youtubeUrl || typeof youtubeUrl !== 'string' || youtubeUrl.length === 0) {
    const q = encodeURIComponent(`${title} ${artist ?? ''} karaoke`.trim());
    youtubeUrl = `https://www.youtube.com/results?search_query=${q}`;
  }
  const newSong: Song = { id, title, artist, score: 0, youtubeUrl };
  state.songs.push(newSong);
  insertSong({ id, title, artist, score: 0, youtubeUrl } as DbSong);
  broadcastState();
  res.status(201).json({ ok: true, id });
});

app.delete('/songs/:id', (req, res) => {
  const { id } = req.params;
  const before = state.songs.length;
  state.songs = state.songs.filter(s => s.id !== id);
  if (state.songs.length === before) return res.status(404).json({ error: 'not found' });
  dbDeleteSong(id);
  broadcastState();
  res.json({ ok: true });
});

app.post('/songs/:id/score', (req, res) => {
  const { id } = req.params;
  const { delta, set } = req.body ?? {};
  const song = state.songs.find(s => s.id === id);
  if (!song) return res.status(404).json({ error: 'not found' });
  if (typeof set === 'number') song.score = set;
  else if (typeof delta === 'number') song.score += delta;
  else return res.status(400).json({ error: 'delta or set required' });
  dbUpdateScore(id, song.score);
  broadcastState();
  res.json({ ok: true, score: song.score });
});

app.post('/songs/:id/url', (req, res) => {
  const { id } = req.params;
  const { youtubeUrl } = req.body ?? {};
  const song = state.songs.find(s => s.id === id);
  if (!song) return res.status(404).json({ error: 'not found' });
  song.youtubeUrl = typeof youtubeUrl === 'string' && youtubeUrl.length > 0 ? youtubeUrl : undefined;
  updateYoutubeUrl(id, song.youtubeUrl ?? null);
  broadcastState();
  res.json({ ok: true });
});

app.post('/timer/start', (req, res) => {
  const { durationSeconds } = req.body ?? {};
  if (typeof durationSeconds === 'number' && durationSeconds > 0) {
    state.timer.durationSeconds = durationSeconds;
    state.timer.remainingSeconds = durationSeconds;
  }
  if (state.timer.remainingSeconds <= 0) state.timer.remainingSeconds = state.timer.durationSeconds;
  state.timer.isRunning = true;
  state.timer.lastTickTs = Date.now();
  broadcastState();
  res.json({ ok: true });
});

app.post('/timer/stop', (_req, res) => {
  recalcRemaining();
  state.timer.isRunning = false;
  state.timer.lastTickTs = undefined;
  broadcastState();
  res.json({ ok: true });
});

app.post('/timer/reset', (_req, res) => {
  state.timer.remainingSeconds = state.timer.durationSeconds;
  state.timer.isRunning = false;
  state.timer.lastTickTs = undefined;
  broadcastState();
  res.json({ ok: true });
});

// Theme settings
app.get('/theme', (_req, res) => {
  res.json(getAllThemeSettings());
});

app.post('/theme', (req, res) => {
  const settings = req.body ?? {};
  for (const [key, value] of Object.entries(settings)) {
    if (typeof value === 'string') setThemeSetting(key, value);
  }
  broadcastThemeUpdate();
  res.json({ ok: true });
});

// Image upload
app.post('/images', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'no file uploaded' });
  const host = req.get('host') || 'localhost:8082';
  const protocol = req.protocol;
  const imageUrl = `${protocol}://${host}/images/${req.file.filename}`;
  res.json({ ok: true, url: imageUrl, filename: req.file.filename });
});

app.get('/images', (_req, res) => {
  const files = fs.readdirSync(imagesDir).map(f => ({
    filename: f,
    url: `/images/${f}`,
  }));
  res.json(files);
});

app.delete('/images/:filename', (req, res) => {
  const { filename } = req.params;
  const filePath = path.join(imagesDir, filename);
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
    res.json({ ok: true });
  } else {
    res.status(404).json({ error: 'not found' });
  }
});

// Socket.IO
io.on('connection', (socket) => {
  recalcRemaining();
  socket.emit('state:update', state);

  socket.on('score:update', ({ id, delta, set }: { id: string; delta?: number; set?: number }) => {
    const song = state.songs.find(s => s.id === id);
    if (!song) return;
    if (typeof set === 'number') song.score = set;
    else if (typeof delta === 'number') song.score += delta;
    dbUpdateScore(id, song.score);
    broadcastState();
  });

  socket.on('timer:control', ({ action, durationSeconds }: { action: 'start' | 'stop' | 'reset'; durationSeconds?: number }) => {
    if (action === 'start') {
      if (typeof durationSeconds === 'number' && durationSeconds > 0) {
        state.timer.durationSeconds = durationSeconds;
        state.timer.remainingSeconds = durationSeconds;
      }
      state.timer.isRunning = true;
      state.timer.lastTickTs = Date.now();
    } else if (action === 'stop') {
      recalcRemaining();
      state.timer.isRunning = false;
      state.timer.lastTickTs = undefined;
    } else if (action === 'reset') {
      state.timer.remainingSeconds = state.timer.durationSeconds;
      state.timer.isRunning = false;
      state.timer.lastTickTs = undefined;
    }
    broadcastState();
  });
});

// Backend always listens on 3001 internally (nginx proxies to it)
// Railway's PORT env var is for nginx, not the backend
// Using 3001 to avoid conflicts with Railway's PORT (which might be 8080)
const BACKEND_PORT = 3001;
server.listen(BACKEND_PORT, '127.0.0.1', () => {
  console.log(`karaoke backend listening on 127.0.0.1:${BACKEND_PORT}`);
});

// Timer tick to keep clients in sync even if no REST calls happen
setInterval(() => {
  const before = state.timer.remainingSeconds;
  recalcRemaining();
  if (state.timer.remainingSeconds !== before) broadcastState();
}, 1000);


