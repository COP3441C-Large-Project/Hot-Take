import { MongoClient } from 'mongodb';

const uri = process.env.MONGODB_URI;

if (!uri) {
  console.error('Error: MONGODB_URI environment variable is not set.');
  process.exit(1);
}

const client = new MongoClient(uri);

let db = null;

export async function connectDB() {
  await client.connect();
  db = client.db();
  console.log(`Connected to MongoDB: ${db.databaseName}`);
}

export function getDB() {
  if (!db) {
    throw new Error('Database not initialized. Call connectDB() first.');
  }
  return db;
}
