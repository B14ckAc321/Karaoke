import express from 'express';
import http from 'http';
import cors from 'cors';
import helmet from 'helmet';
import { Server } from 'socket.io';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { getAllSongs, insertSong, deleteSong as dbDeleteSong, updateScore as dbUpdateScore, updateYoutubeUrl, updateSongTitle, DbSong, getThemeSetting, setThemeSetting, getAllThemeSettings } from './db';
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
  filename: (req, file, cb) => {
    // Use fixed filenames based on the image type to replace existing images
    // This saves storage space by replacing instead of accumulating
    const imageType = (req.body?.type || req.query?.type || 'background') as string; // 'background' or 'logo'
    const filename = imageType === 'logo' ? 'logo.jpg' : 'background.jpg';
    // Delete old file if it exists (to save storage)
    const filePath = path.join(imagesDir, filename);
    if (fs.existsSync(filePath)) {
      try {
        fs.unlinkSync(filePath);
        console.log(`Deleted old ${filename} before upload`);
      } catch (err) {
        console.error(`Error deleting old ${filename}:`, err);
      }
    }
    cb(null, filename);
  },
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
  console.log(`Broadcasting state update: ${state.songs.length} songs, ${io.sockets.sockets.size} connected clients`);
  io.emit('state:update', state);
}

// Debounce timer for score updates - delays list reordering by 2.5 seconds
let scoreUpdateDebounceTimer: ReturnType<typeof setTimeout> | null = null;
const SCORE_UPDATE_DELAY_MS = 2500; // 2.5 seconds

function debouncedBroadcastState() {
  // Clear existing timer if any
  if (scoreUpdateDebounceTimer) {
    clearTimeout(scoreUpdateDebounceTimer);
  }
  
  // Set new timer to broadcast after delay
  scoreUpdateDebounceTimer = setTimeout(() => {
    broadcastState();
    scoreUpdateDebounceTimer = null;
  }, SCORE_UPDATE_DELAY_MS);
}

function broadcastThemeUpdate() {
  const settings = getAllThemeSettings();
  console.log(`Broadcasting theme update to ${io.sockets.sockets.size} connected clients`);
  console.log(`Theme settings: ${Object.keys(settings).length} keys`);
  io.emit('theme:update', settings);
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
app.get('/health', (_req, res) => {
  const dataDir = process.env.DATA_DIR || '/data';
  const dbPath = path.join(dataDir, 'karaoke.db');
  const volumeMounted = fs.existsSync(dataDir);
  const dbExists = fs.existsSync(dbPath);
  let dbSize = 0;
  if (dbExists) {
    try {
      dbSize = fs.statSync(dbPath).size;
    } catch (_) {}
  }
  
  res.json({
    ok: true,
    volume: {
      dataDir,
      mounted: volumeMounted,
      writable: (() => {
        try {
          const testFile = path.join(dataDir, '.test');
          fs.writeFileSync(testFile, 'test');
          fs.unlinkSync(testFile);
          return true;
        } catch (_) {
          return false;
        }
      })(),
    },
    database: {
      path: dbPath,
      exists: dbExists,
      size: dbSize,
    },
  });
});

app.get('/state', (_req, res) => {
  recalcRemaining();
  console.log(`GET /state - returning ${state.songs.length} songs`);
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
  // Use debounced broadcast for REST endpoint too
  debouncedBroadcastState();
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

app.post('/songs/:id/update', (req, res) => {
  const { id } = req.params;
  const { title, artist } = req.body ?? {};
  const song = state.songs.find(s => s.id === id);
  if (!song) return res.status(404).json({ error: 'not found' });
  if (typeof title === 'string' && title.length > 0) {
    song.title = title;
  }
  if (artist !== undefined) {
    song.artist = typeof artist === 'string' && artist.length > 0 ? artist : undefined;
  }
  updateSongTitle(id, song.title, song.artist);
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
  const settings = getAllThemeSettings();
  console.log(`GET /theme - returning ${Object.keys(settings).length} theme settings`);
  res.json(settings);
});

app.post('/theme', (req, res) => {
  const settings = req.body ?? {};
  console.log(`POST /theme - saving ${Object.keys(settings).length} settings`);
  let savedCount = 0;
  for (const [key, value] of Object.entries(settings)) {
    if (typeof value === 'string') {
      setThemeSetting(key, value);
      savedCount++;
      console.log(`  - ${key}: ${value}`);
    }
  }
  console.log(`Saved ${savedCount} theme settings to database`);
  
  // Verify settings were saved
  const allSettings = getAllThemeSettings();
  console.log(`Database now contains ${Object.keys(allSettings).length} theme settings`);
  
  console.log('Broadcasting theme update...');
  broadcastThemeUpdate();
  res.json({ ok: true, saved: savedCount, total: Object.keys(allSettings).length });
});

// Image upload - stores images as base64 in database
app.post('/upload/image', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'no file uploaded' });
  const imageType = req.body?.type || req.query?.type || 'background'; // 'background' or 'logo'
  const settingKey = imageType === 'logo' ? 'logoImageUrl' : 'backgroundImageUrl';
  
  try {
    // Read the uploaded file and convert to base64
    const imageBuffer = fs.readFileSync(req.file.path);
    const base64Image = imageBuffer.toString('base64');
    const mimeType = req.file.mimetype || 'image/jpeg';
    const dataUri = `data:${mimeType};base64,${base64Image}`;
    
    // Store in database (replaces existing image)
    setThemeSetting(settingKey, dataUri);
    console.log(`Image uploaded and stored in database: ${settingKey} (${imageBuffer.length} bytes, base64: ${base64Image.length} chars)`);
    
    // Delete the temporary file
    fs.unlinkSync(req.file.path);
    
    // Broadcast theme update so all clients get the new image
    broadcastThemeUpdate();
    
    // Return the data URI (frontend can use this directly)
    res.json({ ok: true, url: dataUri, key: settingKey });
  } catch (err) {
    console.error('Error processing image upload:', err);
    // Clean up temp file if it exists
    if (req.file?.path && fs.existsSync(req.file.path)) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    res.status(500).json({ error: 'failed to process image' });
  }
});

// Get image from database (serves base64 data URI as image)
// This endpoint is optional since frontend can use data URIs directly
app.get('/images/:key', (req, res) => {
  const { key } = req.params;
  const settingKey = key === 'logo' ? 'logoImageUrl' : 'backgroundImageUrl';
  const dataUri = getThemeSetting(settingKey);
  
  if (!dataUri || !dataUri.startsWith('data:')) {
    return res.status(404).json({ error: 'image not found' });
  }
  
  // Extract mime type and base64 data from data URI
  const match = dataUri.match(/^data:([^;]+);base64,(.+)$/);
  if (!match) {
    return res.status(500).json({ error: 'invalid image format' });
  }
  
  const mimeType = match[1];
  const base64Data = match[2];
  const imageBuffer = Buffer.from(base64Data, 'base64');
  
  res.setHeader('Content-Type', mimeType);
  res.setHeader('Cache-Control', 'public, max-age=31536000'); // Cache for 1 year
  res.send(imageBuffer);
});

// Socket.IO
io.on('connection', (socket) => {
  console.log(`Socket.IO client connected (total: ${io.sockets.sockets.size})`);
  // Send initial state to newly connected client
  recalcRemaining();
  socket.emit('state:update', state);
  // Also send theme settings to newly connected client
  socket.emit('theme:update', getAllThemeSettings());
  recalcRemaining();
  socket.emit('state:update', state);

  socket.on('score:update', ({ id, delta, set }: { id: string; delta?: number; set?: number }) => {
    const song = state.songs.find(s => s.id === id);
    if (!song) return;
    if (typeof set === 'number') song.score = set;
    else if (typeof delta === 'number') song.score += delta;
    dbUpdateScore(id, song.score);
    // Update score immediately in state but delay reordering/broadcast
    // This allows users to click multiple times without the list jumping around
    debouncedBroadcastState();
    // Still emit immediate update to all clients for UI responsiveness
    // but don't reorder the list yet
    io.emit('score:updated', { id, score: song.score });
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

// Periodic state broadcast to ensure all clients stay synced (especially when timer is stopped)
setInterval(() => {
  broadcastState();
}, 5000);
