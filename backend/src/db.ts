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
if (!fs.existsSync(dataDir)) {
  console.log(`Creating data directory: ${dataDir}`);
  fs.mkdirSync(dataDir, { recursive: true });
}
const dbPath = path.join(dataDir, 'karaoke.db');
console.log(`Database path: ${dbPath}`);

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


