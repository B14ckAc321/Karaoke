import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';

export type DbSong = {
  id: string;
  title: string;
  artist?: string | null;
  score: number;
  youtubeUrl?: string | null;
};

const dataDir = process.env.DATA_DIR || '/data';
console.log(`Using data directory: ${dataDir}`);
console.log(`DATA_DIR environment variable: ${process.env.DATA_DIR || 'not set (using default /data)'}`);

if (!fs.existsSync(dataDir)) {
  console.log(`Creating data directory: ${dataDir}`);
  fs.mkdirSync(dataDir, { recursive: true });
} else {
  console.log(`Data directory already exists: ${dataDir}`);
}

// Check if directory is writable
try {
  const testFile = path.join(dataDir, '.volume-test');
  fs.writeFileSync(testFile, 'test');
  fs.unlinkSync(testFile);
  console.log(`✓ Data directory is writable: ${dataDir}`);
} catch (error) {
  console.error(`✗ Data directory is NOT writable: ${dataDir}`, error);
  console.error('WARNING: Volume may not be mounted correctly!');
}

const dbPath = path.join(dataDir, 'karaoke.db');
console.log(`Database path: ${dbPath}`);

// Check if database file exists (indicates persistence)
if (fs.existsSync(dbPath)) {
  const stats = fs.statSync(dbPath);
  console.log(`Database file exists (${stats.size} bytes, modified: ${stats.mtime})`);
} else {
  console.log('Database file does not exist yet (will be created)');
}

let db: InstanceType<typeof Database>;
try {
  const database = new Database(dbPath);
  console.log('Database initialized successfully');
  
  // Set WAL mode for better concurrency
  database.pragma('journal_mode = WAL');
  console.log('Database is writable');
  db = database;
} catch (error) {
  console.error('Failed to initialize database:', error);
  console.error('Make sure /data volume is mounted in Railway settings!');
  throw error;
}

export { db };

db.prepare(`
  CREATE TABLE IF NOT EXISTS songs (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT,
    score INTEGER NOT NULL DEFAULT 0,
    youtube_url TEXT
  )
`).run();

db.prepare(`
  CREATE TABLE IF NOT EXISTS theme_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
`).run();

export function getAllSongs(): DbSong[] {
  const rows = db.prepare('SELECT id, title, artist, score, youtube_url as youtubeUrl FROM songs ORDER BY score DESC, title COLLATE NOCASE').all();
  return rows as DbSong[];
}

export function insertSong(song: DbSong): void {
  db.prepare('INSERT INTO songs (id, title, artist, score, youtube_url) VALUES (?, ?, ?, ?, ?)')
    .run(song.id, song.title, song.artist ?? null, song.score, song.youtubeUrl ?? null);
}

export function deleteSong(id: string): boolean {
  const info = db.prepare('DELETE FROM songs WHERE id = ?').run(id);
  return info.changes > 0;
}

export function updateScore(id: string, score: number): void {
  db.prepare('UPDATE songs SET score = ? WHERE id = ?').run(score, id);
}

export function updateYoutubeUrl(id: string, url: string | null): void {
  db.prepare('UPDATE songs SET youtube_url = ? WHERE id = ?').run(url, id);
}

export function getThemeSetting(key: string): string | null {
  const row = db.prepare('SELECT value FROM theme_settings WHERE key = ?').get(key) as { value: string } | undefined;
  return row?.value ?? null;
}

export function setThemeSetting(key: string, value: string): void {
  db.prepare('INSERT OR REPLACE INTO theme_settings (key, value) VALUES (?, ?)').run(key, value);
}

export function getAllThemeSettings(): Record<string, string> {
  const rows = db.prepare('SELECT key, value FROM theme_settings').all() as Array<{ key: string; value: string }>;
  const result: Record<string, string> = {};
  for (const row of rows) result[row.key] = row.value;
  return result;
}


