import crypto from 'node:crypto';
import bcrypt from 'bcrypt';
import { getDB } from './db.js';
import { scoreMatch } from '../services/matching.js';

// Helper func to generate short IDs w/ a prefix
function id(prefix) {
  return `${prefix}_${crypto.randomUUID().slice(0, 8)}`;
}

// Helper func to get current timestamp in ISO format
function now() {
  return new Date().toISOString();
}

// Removes sensitive fields before sending user to client
function sanitizeUser(user) {
  return {
    id: user.id,
    username: user.username,
    email: user.email,
    bio: user.bio,
    tags: user.tags,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt
  };
}

export function createStore() {
  // Sessions stay in-memory (token → userId)
  const sessions = new Map();

  // Finds user by ID from MongoDB
  async function findUserById(userId) {
    return getDB().collection('users').findOne({ id: userId });
  }

  // Gets user from auth token
  async function getUserFromToken(token) {
    const userId = sessions.get(token);
    return userId ? findUserById(userId) : undefined;
  }

  // Creates a session token
  function createSession(userId) {
    const token = crypto.randomUUID();
    sessions.set(token, userId);
    return token;
  }

  return {
    // Registers a new user
    async register({ username, email, password }) {
      const col = getDB().collection('users');

      // Prevents duplicate emails
      const existing = await col.findOne({ email: email.toLowerCase() });
      if (existing) {
        return { error: 'Email already registered.' };
      }

      const timestamp = now();
      const user = {
        id: id('user'),
        username,
        email: email.toLowerCase(),
        passwordHash: await bcrypt.hash(password, 10),
        bio: '',
        tags: [],
        createdAt: timestamp,
        updatedAt: timestamp,
        lastActiveAt: timestamp
      };

      await col.insertOne(user);

      return {
        token: createSession(user.id),
        user: sanitizeUser(user)
      };
    },

    // Logins user
    async login({ email, password }) {
      const col = getDB().collection('users');

      const user = await col.findOne({ email: email.toLowerCase() });

      // Invalid credentials
      if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
        return { error: 'Invalid email or password.' };
      }

      // Updates activity timestamp in MongoDB
      await col.updateOne({ id: user.id }, { $set: { lastActiveAt: now() } });

      return {
        token: createSession(user.id),
        user: sanitizeUser(user)
      };
    },

    // Gets currently logged in user
    async getCurrentUser(token) {
      const user = await getUserFromToken(token);
      return user ? sanitizeUser(user) : null;
    },

    // Updates user bio and tags
    async updateInterests(token, { bio, tags }) {
      const user = await getUserFromToken(token);

      if (!user) {
        return { error: 'Unauthorized.' };
      }

      // Cleans bio
      const cleanBio = bio.trim();
      // Normalizes tags: lowercase, removes duplicates, max 10 tags
      const cleanTags = [...new Set(tags.map((tag) => tag.trim().toLowerCase()).filter(Boolean))].slice(0, 10);
      const timestamp = now();

      await getDB().collection('users').updateOne(
        { id: user.id },
        { $set: { bio: cleanBio, tags: cleanTags, updatedAt: timestamp, lastActiveAt: timestamp } }
      );

      return { user: sanitizeUser({ ...user, bio: cleanBio, tags: cleanTags, updatedAt: timestamp }) };
    },

    // Gets matches for current user
    async listMatches(token) {
      const currentUser = await getUserFromToken(token);

      if (!currentUser) {
        return { error: 'Unauthorized.' };
      }

      const candidates = await getDB().collection('users').find({ id: { $ne: currentUser.id } }).toArray();

      const results = candidates
        .map((candidate) => {
          const match = scoreMatch(currentUser, candidate);
          return {
            userId: candidate.id,
            username: candidate.username,
            bio: candidate.bio,
            tags: candidate.tags,
            score: match.score,
            sharedTags: match.sharedTags,
            sharedTerms: match.sharedTerms
          };
        })
        // Only relevant matches
        .filter((candidate) => candidate.score > 0)
        // Sorts best first
        .sort((left, right) => right.score - left.score);

      return { matches: results };
    },

    // Lists chats for current user
    async listChats(token) {
      const currentUser = await getUserFromToken(token);

      if (!currentUser) {
        return { error: 'Unauthorized.' };
      }

      const chats = await getDB().collection('chats').find({ participantIds: currentUser.id }).toArray();

      const results = await Promise.all(
        chats.map(async (chat) => {
          // Gets other participant
          const otherUserId = chat.participantIds.find((pid) => pid !== currentUser.id);
          const otherUser = otherUserId ? await findUserById(otherUserId) : null;
          const lastMessage = chat.messages.at(-1) ?? null;
          const match = otherUser ? scoreMatch(currentUser, otherUser) : { score: 0, sharedTags: [] };

          return {
            id: chat.id,
            participant: otherUser ? sanitizeUser(otherUser) : null,
            matchScore: match.score,
            sharedTags: match.sharedTags,
            lastMessage
          };
        })
      );

      return { chats: results };
    },

    // Gets messages for a chat
    async getChatMessages(token, chatId) {
      const currentUser = await getUserFromToken(token);

      if (!currentUser) {
        return { error: 'Unauthorized.' };
      }

      const chat = await getDB().collection('chats').findOne({ id: chatId, participantIds: currentUser.id });

      if (!chat) {
        return { error: 'Chat not found.' };
      }

      return { messages: chat.messages };
    },

    // Starts a new chat w/ a match
    async startChat(token, matchUserId) {
      const currentUser = await getUserFromToken(token);

      if (!currentUser) {
        return { error: 'Unauthorized.' };
      }

      const matchUser = await findUserById(matchUserId);

      if (!matchUser || matchUser.id === currentUser.id) {
        return { error: 'Match user not found.' };
      }

      const col = getDB().collection('chats');

      // Checks if chat already exists
      const existingChat = await col.findOne({ participantIds: { $all: [currentUser.id, matchUser.id] } });

      if (existingChat) {
        return { chatId: existingChat.id };
      }

      const chat = {
        id: id('chat'),
        participantIds: [currentUser.id, matchUser.id],
        createdAt: now(),
        updatedAt: now(),
        messages: []
      };

      await col.insertOne(chat);
      return { chatId: chat.id };
    },

    // Sends a message in a chat
    async sendMessage(token, chatId, text) {
      const currentUser = await getUserFromToken(token);

      if (!currentUser) {
        return { error: 'Unauthorized.' };
      }

      const col = getDB().collection('chats');
      const chat = await col.findOne({ id: chatId, participantIds: currentUser.id });

      if (!chat) {
        return { error: 'Chat not found.' };
      }

      const message = {
        id: id('msg'),
        senderId: currentUser.id,
        text: text.trim(),
        sentAt: now()
      };

      // Adds message and updates chat timestamp
      await col.updateOne(
        { id: chatId },
        { $push: { messages: message }, $set: { updatedAt: now() } }
      );

      // Updates user activity
      await getDB().collection('users').updateOne(
        { id: currentUser.id },
        { $set: { lastActiveAt: now() } }
      );

      return { message };
    }
  };
}
