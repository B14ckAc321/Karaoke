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
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
const dbPath = path.join(dataDir, 'karaoke.db');

export const db = new Database(dbPath);

db.pragma('journal_mode = WAL');

db.prepare(`
  CREATE TABLE IF NOT EXISTS songs (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT,
    score INTEGER NOT NULL DEFAULT 0,
    youtube_url TEXT
  )
`).run();

export function getAllSongs(): DbSong[] {
  const rows = db.prepare('SELECT id, title, artist, score, youtube_url as youtubeUrl FROM songs ORDER BY title COLLATE NOCASE').all();
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


