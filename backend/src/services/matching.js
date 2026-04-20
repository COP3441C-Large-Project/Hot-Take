import { getDB } from '../data/db.js';
import { updateEmbedding } from '../matching/updateEmbedding.js';

const EMBEDDING_DIMENSION = 384;
const DEFAULT_TOP_K = 10;
const MIN_MATCH_SIMILARITY = 0.15;

function normalizeEmbedding(value) {
  if (!Array.isArray(value) || value.length !== EMBEDDING_DIMENSION) {
    return null;
  }

  const normalized = value
    .map((entry) => Number(entry))
    .filter((entry) => Number.isFinite(entry));

  if (normalized.length !== EMBEDDING_DIMENSION) {
    return null;
  }

  return normalized;
}

function dotProduct(left, right) {
  let sum = 0;
  for (let index = 0; index < left.length; index += 1) {
    sum += left[index] * right[index];
  }
  return sum;
}

function magnitude(vector) {
  return Math.sqrt(dotProduct(vector, vector));
}

function cosineSimilarity(left, right) {
  if (!left || !right || left.length !== right.length) {
    return 0;
  }

  const leftMagnitude = magnitude(left);
  const rightMagnitude = magnitude(right);

  if (!leftMagnitude || !rightMagnitude) {
    return 0;
  }

  return dotProduct(left, right) / (leftMagnitude * rightMagnitude);
}

function buildPromptFromProfile({ bio = '', tags = [] }) {
  const normalizedTags = Array.isArray(tags)
    ? tags.map((tag) => String(tag).trim()).filter(Boolean)
    : [];

  if (normalizedTags.length === 0) {
    return bio.trim();
  }

  return `${bio.trim()}\nTopics: ${normalizedTags.join(', ')}`.trim();
}

function toCacheRecord(user) {
  return {
    id: user.id,
    username: user.username ?? '',
    bio: user.bio ?? '',
    tags: Array.isArray(user.tags) ? user.tags : [],
    userProfile: normalizeEmbedding(user.userProfile ?? user.UserProfile),
    lastEmbedding: normalizeEmbedding(user.lastEmbedding),
    topicCount: Number.isInteger(user.topicCount ?? user.TopicCount)
      ? (user.topicCount ?? user.TopicCount)
      : 0,
    lastUpdateTimestamp: user.lastUpdateTimestamp ?? null,
    lastActiveTimestamp: user.lastActiveAt ?? user.lastActiveTimestamp ?? null,
  };
}

function scoreFromSimilarity(similarity) {
  return Math.max(0, Math.min(100, Math.round(similarity * 100)));
}

export function scoreMatch(currentUser, candidate) {
  const currentTags = new Set(
    Array.isArray(currentUser.tags)
      ? currentUser.tags.map((tag) => String(tag).trim().toLowerCase()).filter(Boolean)
      : []
  );
  const candidateTags = new Set(
    Array.isArray(candidate.tags)
      ? candidate.tags.map((tag) => String(tag).trim().toLowerCase()).filter(Boolean)
      : []
  );

  const sharedTags = [...currentTags].filter((tag) => candidateTags.has(tag));
  const tagScore = sharedTags.length * 20;

  return {
    score: Math.max(0, Math.min(100, tagScore)),
    sharedTags,
    sharedTerms: [],
  };
}

export class MatchingService {
  constructor({ topK = DEFAULT_TOP_K, minSimilarity = MIN_MATCH_SIMILARITY } = {}) {
    this.userCache = new Map();
    this.topK = topK;
    this.minSimilarity = minSimilarity;
  }

  async init() {
    const users = await getDB().collection('users').find({}).toArray();
    this.userCache.clear();

    for (const user of users) {
      this.userCache.set(user.id, toCacheRecord(user));
    }
  }

  getCachedUser(userId) {
    return this.userCache.get(userId) ?? null;
  }

  async refreshUser(userId) {
    const user = await getDB().collection('users').findOne({ id: userId });

    if (!user) {
      this.userCache.delete(userId);
      return null;
    }

    const cacheRecord = toCacheRecord(user);
    this.userCache.set(userId, cacheRecord);
    return cacheRecord;
  }

  async updateUserAndFindMatches({ userId, bio, tags = [], topK = this.topK }) {
    const cachedUser = this.getCachedUser(userId) ?? await this.refreshUser(userId);

    if (!cachedUser) {
      return { error: 'User not found.' };
    }

    const prompt = buildPromptFromProfile({ bio, tags });
    if (!prompt) {
      return { error: 'A non-empty prompt is required.' };
    }

    const lastUpdateTimestampSeconds = cachedUser.lastUpdateTimestamp
      ? Math.floor(new Date(cachedUser.lastUpdateTimestamp).getTime() / 1000)
      : Math.floor(Date.now() / 1000);

    const embeddingResult = await updateEmbedding({
      userEmbedding: cachedUser.userProfile,
      newPrompt: prompt,
      lastUpdateTimestamp: lastUpdateTimestampSeconds,
      lastEmbedding: cachedUser.lastEmbedding,
    });

    if (!embeddingResult.success) {
      throw new Error(embeddingResult.error ?? 'Embedding update failed.');
    }

    const updatedEmbedding = normalizeEmbedding(embeddingResult.updatedEmbedding);
    if (!updatedEmbedding) {
      throw new Error('Embedding model returned an invalid profile vector.');
    }

    const topicEmbedding = normalizeEmbedding(embeddingResult.topicEmbedding) ?? updatedEmbedding;
    const timestamp = new Date().toISOString();
    const nextTopicCount = (cachedUser.topicCount ?? 0) + (embeddingResult.skipped ? 0 : 1);

    await getDB().collection('users').updateOne(
      { id: userId },
      {
        $set: {
          userProfile: updatedEmbedding,
          lastEmbedding: topicEmbedding,
          topicCount: nextTopicCount,
          lastUpdateTimestamp: timestamp,
          lastActiveAt: timestamp,
        },
      }
    );

    this.userCache.set(userId, {
      ...cachedUser,
      bio,
      tags,
      userProfile: updatedEmbedding,
      lastEmbedding: topicEmbedding,
      topicCount: nextTopicCount,
      lastUpdateTimestamp: timestamp,
      lastActiveTimestamp: timestamp,
    });

    const matches = this.findMatchesForEmbedding({
      userId,
      embedding: topicEmbedding,
      topK,
      matchInput: prompt,
    });

    return {
      updatedEmbedding,
      topicEmbedding,
      matchInput: prompt,
      skipped: Boolean(embeddingResult.skipped),
      similarity: embeddingResult.similarity ?? null,
      updateCoefficient: embeddingResult.updateCoefficient ?? null,
      matches,
    };
  }

  findMatchesForEmbedding({ userId, embedding, topK = this.topK, matchInput = '' }) {
    const sourceUser = this.getCachedUser(userId);
    const sourceEmbedding = normalizeEmbedding(embedding) ?? sourceUser?.userProfile ?? null;

    if (!sourceEmbedding) {
      return [];
    }

    const results = [];

    for (const [candidateId, candidate] of this.userCache.entries()) {
      if (candidateId === userId || !candidate.userProfile) {
        continue;
      }

      const similarity = cosineSimilarity(sourceEmbedding, candidate.userProfile);
      if (similarity < this.minSimilarity) {
        continue;
      }

      results.push({
        userId: candidate.id,
        username: candidate.username,
        bio: candidate.bio,
        tags: candidate.tags,
        score: scoreFromSimilarity(similarity),
        similarity,
        matchInput,
      });
    }

    return results
      .sort((left, right) => right.similarity - left.similarity)
      .slice(0, topK)
      .map(({ similarity, ...result }) => result);
  }
}
