import crypto from 'node:crypto';
import bcrypt from 'bcrypt';
import { getDB } from './db.js';
import { scoreMatch } from '../services/matching.js';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '7d';

if (!JWT_SECRET){
  throw new Error('JWT_SECRET environment variable is required.');
}

function signToken(userId){
  return jwt.sign({sub: userId}, JWT_SECRET, {expiresIn: JWT_EXPIRES_IN});
}
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
  
  //Gets user from auth token 
  async function getUserFromToken(token){
    if (!token)
      return undefined;
    try {
      const payload = jwt.verify(token, JWT_SECRET);
      const userId = typeof payload === 'object' ? payload.sub: undefined;
      if (typeof userId !== 'string')
        return undefined;
      return findUserById(userId);
    } catch {
      return undefined;
    }
  }
  
  // Finds user by ID from MongoDB
  async function findUserById(userId) {
    return getDB().collection('users').findOne({ id: userId });
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
          emailVerified: false,  // add this line
          bio: '',
          tags: [],
          createdAt: timestamp,
          updatedAt: timestamp,
          lastActiveAt: timestamp
        };

      await col.insertOne(user);

      return {
        token: signToken(user.id),
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

      if (!user.emailVerified) {
        return { error: 'Please verify your email before logging in.' };
      }

      // Updates activity timestamp in MongoDB
      await col.updateOne({ id: user.id }, { $set: { lastActiveAt: now() } });

      return {
        token: signToken(user.id),
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
    },

    async sendVerificationEmail(userId, sendEmail) {
      const col = getDB().collection('users');
      const user = await findUserById(userId);
      if (!user) return { error: 'User not found.' };
 
      // Generate a token and expiry (24 hours)
      const verifyToken = crypto.randomUUID();
      const expiry = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
 
      await col.updateOne(
        { id: userId },
        { $set: { verifyToken, verifyTokenExpiry: expiry } }
      );
      console.log('Verification URL:', `${process.env.APP_URL}/verify-email?token=${verifyToken}`);
      await sendEmail({
        to: user.email,
        subject: 'verify your hot take account',
        text: `click to verify: ${process.env.APP_URL}/verify-email?token=${verifyToken}`,
        html: `
        <div style="font-family: monospace; max-width: 480px; margin: 0 auto; padding: 40px 20px;">
          <h1 style="font-size: 2rem; margin-bottom: 4px;">hot take<span style="color:#d44b3a">.</span></h1>
          <p style="color: #5c5752; margin-bottom: 32px;">interest-based matchmaking</p>
          <p style="margin-bottom: 24px;">click the button below to verify your email address.</p>
          <a 
            href="${process.env.APP_URL}/verify-email?token=${verifyToken}" 
            target="_blank" 
            rel="noopener noreferrer"
            style="display: inline-block; background-color: #d44b3a; color: #ffffff; padding: 12px 28px; border-radius: 8px; text-decoration: none; font-family: monospace; font-weight: bold;"
          >
            VERIFY EMAIL
          </a>
          <p style="margin-top: 24px; font-size: 0.85rem; color: #5c5752;">
            or copy this link into your browser:<br/>
            <span style="word-break:break-all;">${process.env.APP_URL}/verify-email?token=${verifyToken}</span>
          </p>
          <p style="margin-top: 32px; font-size: 0.75rem; color: #9e9894;">
            this link expires in 24 hours. if you didn't create an account, ignore this email.
          </p>
        </div>
      `
      });
 
      return { ok: true };
    },
 
    // Verifies email token
    async verifyEmail(verifyToken) {
      const col = getDB().collection('users');
      const user = await col.findOne({ verifyToken });
 
      if (!user) return { error: 'Invalid or expired verification link.' };
      if (new Date(user.verifyTokenExpiry) < new Date()) {
        return { error: 'Verification link has expired.' };
      }
 
      await col.updateOne(
        { id: user.id },
        { $set: { emailVerified: true }, $unset: { verifyToken: '', verifyTokenExpiry: '' } }
      );
 
      return { token: signToken(user.id), user: sanitizeUser({ ...user, emailVerified: true }) };
    },
 
    // Sends forgot password email
    async sendPasswordResetEmail(email, sendEmail) {
      const col = getDB().collection('users');
      const user = await col.findOne({ email: email.toLowerCase() });
 
      // Don't reveal whether email exists
      if (!user) return { ok: true };
 
      const resetToken = crypto.randomUUID();
      const expiry = new Date(Date.now() + 60 * 60 * 1000).toISOString(); // 1 hour
 
      await col.updateOne(
        { id: user.id },
        { $set: { resetToken, resetTokenExpiry: expiry } }
      );
 
      await sendEmail({
        to: user.email,
        subject: 'reset your hot take password',
        text: `click to reset: ${process.env.APP_URL}/reset-password?token=${resetToken}`,
        html: `
          <div style="font-family: monospace; max-width: 480px; margin: 0 auto; padding: 40px 20px;">
            <h1 style="font-size: 2rem; margin-bottom: 4px;">hot take<span style="color:#d44b3a">.</span></h1>
            <p style="color: #5c5752; margin-bottom: 32px;">interest-based matchmaking</p>
            <p style="margin-bottom: 24px;">someone requested a password reset for this account.</p>
            <a href="${process.env.APP_URL}/reset-password?token=${resetToken}"
               style="display:inline-block;background:#d44b3a;color:#fff;padding:12px 28px;border-radius:8px;text-decoration:none;font-family:monospace;">
              reset password →
            </a>
            <p style="margin-top: 32px; font-size: 0.75rem; color: #9e9894;">
              this link expires in 1 hour. if you didn't request this, ignore this email.
            </p>
          </div>
        `
      });
 
      return { ok: true };
    },
 
    // Resets password using token
    async resetPassword(resetToken, newPassword) {
      const col = getDB().collection('users');
      const user = await col.findOne({ resetToken });
 
      if (!user) return { error: 'Invalid or expired reset link.' };
      if (new Date(user.resetTokenExpiry) < new Date()) {
        return { error: 'Reset link has expired.' };
      }
 
      await col.updateOne(
        { id: user.id },
        {
          $set: { passwordHash: await bcrypt.hash(newPassword, 10), updatedAt: now() },
          $unset: { resetToken: '', resetTokenExpiry: '' }
        }
      );
 
      return { token: signToken(user.id), user: sanitizeUser(user) };
    },
 
  };
}
