import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Anthropic from '@anthropic-ai/sdk';
import OpenAI from 'openai';
import { GoogleGenerativeAI } from '@google/generative-ai';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize AI clients lazily to avoid runtime errors during deployment
function getAnthropicClient() {
  return new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY || functions.config().anthropic?.api_key,
  });
}

function getOpenAIClient() {
  return new OpenAI({
    apiKey: process.env.OPENAI_API_KEY || functions.config().openai?.api_key,
  });
}

function getGeminiClient() {
  return new GoogleGenerativeAI(
    process.env.GOOGLE_API_KEY || functions.config().google?.api_key || ''
  );
}

// Rate limiting helper
async function checkRateLimit(userId: string): Promise<void> {
  const now = new Date();
  const hourAgo = new Date(now.getTime() - 60 * 60 * 1000);

  const usageRef = admin.firestore()
    .collection('usage')
    .doc(userId);

  const doc = await usageRef.get();
  const data = doc.data();

  if (data && data.lastReset > hourAgo) {
    if (data.requestCount >= 100) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Rate limit exceeded. Maximum 100 requests per hour.'
      );
    }
  }
}

// Log usage helper
async function logUsage(
  userId: string,
  model: string,
  inputTokens: number,
  outputTokens: number,
  cost: number
): Promise<void> {
  const usageRef = admin.firestore()
    .collection('usage')
    .doc(userId);

  const now = new Date();

  await admin.firestore().runTransaction(async (transaction) => {
    const doc = await transaction.get(usageRef);
    const data = doc.data();

    const hourAgo = new Date(now.getTime() - 60 * 60 * 1000);
    const shouldReset = !data || !data.lastReset || data.lastReset.toDate() < hourAgo;

    if (shouldReset) {
      transaction.set(usageRef, {
        userId,
        requestCount: 1,
        totalTokens: inputTokens + outputTokens,
        totalCost: cost,
        lastReset: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      transaction.update(usageRef, {
        requestCount: admin.firestore.FieldValue.increment(1),
        totalTokens: admin.firestore.FieldValue.increment(inputTokens + outputTokens),
        totalCost: admin.firestore.FieldValue.increment(cost),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  // Also log to history collection
  await admin.firestore().collection('usage_history').add({
    userId,
    model,
    inputTokens,
    outputTokens,
    cost,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// Main chat function with multi-model support
export const chat = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { model, messages, maxTokens = 1000, temperature = 0.7 } = data;

  // Validate input
  if (!model || !messages || !Array.isArray(messages)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid request parameters');
  }

  // Check rate limit
  await checkRateLimit(userId);

  let response: any;
  let inputTokens = 0;
  let outputTokens = 0;
  let cost = 0;

  try {
    // Route to appropriate model
    if (model.startsWith('claude-')) {
      // Anthropic Claude models
      const anthropic = getAnthropicClient();
      const result = await anthropic.messages.create({
        model: model,
        max_tokens: maxTokens,
        temperature: temperature,
        messages: messages,
      });

      inputTokens = result.usage.input_tokens;
      outputTokens = result.usage.output_tokens;

      // Calculate cost (Claude 3.5 Sonnet pricing)
      cost = (inputTokens / 1000000) * 3.0 + (outputTokens / 1000000) * 15.0;

      response = {
        content: result.content[0].text,
        model: result.model,
        usage: {
          inputTokens,
          outputTokens,
          totalTokens: inputTokens + outputTokens,
        },
      };

    } else if (model.startsWith('gpt-')) {
      // OpenAI GPT models
      const openai = getOpenAIClient();
      const result = await openai.chat.completions.create({
        model: model,
        messages: messages,
        max_tokens: maxTokens,
        temperature: temperature,
      });

      inputTokens = result.usage?.prompt_tokens || 0;
      outputTokens = result.usage?.completion_tokens || 0;

      // Calculate cost (GPT-4 pricing example)
      cost = (inputTokens / 1000000) * 30.0 + (outputTokens / 1000000) * 60.0;

      response = {
        content: result.choices[0].message.content,
        model: result.model,
        usage: {
          inputTokens,
          outputTokens,
          totalTokens: inputTokens + outputTokens,
        },
      };

    } else if (model.startsWith('gemini-')) {
      // Google Gemini models
      const genAI = getGeminiClient();
      const geminiModel = genAI.getGenerativeModel({ model: model });

      // Convert messages to Gemini format
      const prompt = messages.map((m: any) => m.content).join('\n');

      const result = await geminiModel.generateContent(prompt);
      const geminiResponse = await result.response;

      // Estimate tokens (Gemini doesn't provide exact count in free tier)
      inputTokens = Math.ceil(prompt.length / 4);
      outputTokens = Math.ceil((geminiResponse.text()?.length || 0) / 4);

      // Gemini pricing (estimated)
      cost = (inputTokens / 1000000) * 0.5 + (outputTokens / 1000000) * 1.5;

      response = {
        content: geminiResponse.text(),
        model: model,
        usage: {
          inputTokens,
          outputTokens,
          totalTokens: inputTokens + outputTokens,
        },
      };

    } else {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Unsupported model: ${model}`
      );
    }

    // Log usage
    await logUsage(userId, model, inputTokens, outputTokens, cost);

    return response;

  } catch (error: any) {
    console.error('Chat error:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'An error occurred while processing your request'
    );
  }
});

// Get available models
export const getModels = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  return {
    models: [
      {
        id: 'claude-3-5-sonnet-20240620',
        name: 'Claude 3.5 Sonnet',
        provider: 'Anthropic',
        description: 'Most intelligent model, best for complex tasks',
        inputCost: 3.0,  // per million tokens
        outputCost: 15.0,
        maxTokens: 200000,
      },
      {
        id: 'claude-3-opus-20240229',
        name: 'Claude 3 Opus',
        provider: 'Anthropic',
        description: 'Powerful model for complex reasoning',
        inputCost: 15.0,
        outputCost: 75.0,
        maxTokens: 200000,
      },
      {
        id: 'claude-3-haiku-20240307',
        name: 'Claude 3 Haiku',
        provider: 'Anthropic',
        description: 'Fastest and most compact model',
        inputCost: 0.25,
        outputCost: 1.25,
        maxTokens: 200000,
      },
      {
        id: 'gpt-4-turbo',
        name: 'GPT-4 Turbo',
        provider: 'OpenAI',
        description: 'OpenAI\'s most capable model',
        inputCost: 10.0,
        outputCost: 30.0,
        maxTokens: 128000,
      },
      {
        id: 'gpt-4',
        name: 'GPT-4',
        provider: 'OpenAI',
        description: 'Powerful reasoning model',
        inputCost: 30.0,
        outputCost: 60.0,
        maxTokens: 8192,
      },
      {
        id: 'gpt-3.5-turbo',
        name: 'GPT-3.5 Turbo',
        provider: 'OpenAI',
        description: 'Fast and cost-effective',
        inputCost: 0.5,
        outputCost: 1.5,
        maxTokens: 16385,
      },
      {
        id: 'gemini-pro',
        name: 'Gemini Pro',
        provider: 'Google',
        description: 'Google\'s advanced AI model (Free tier)',
        inputCost: 0.0,
        outputCost: 0.0,
        maxTokens: 32760,
      },
    ],
  };
});

// Get user usage statistics
export const getUsage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;

  const usageDoc = await admin.firestore()
    .collection('usage')
    .doc(userId)
    .get();

  const usageData = usageDoc.data();

  // Get usage history for the last 30 days
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const historySnapshot = await admin.firestore()
    .collection('usage_history')
    .where('userId', '==', userId)
    .where('timestamp', '>=', thirtyDaysAgo)
    .orderBy('timestamp', 'desc')
    .limit(100)
    .get();

  const history = historySnapshot.docs.map(doc => doc.data());

  return {
    current: usageData || {
      requestCount: 0,
      totalTokens: 0,
      totalCost: 0,
    },
    history,
  };
});

// Save conversation
export const saveConversation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { title, messages, model } = data;

  const conversationRef = await admin.firestore()
    .collection('conversations')
    .add({
      userId,
      title: title || 'Untitled Conversation',
      messages,
      model,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  return { id: conversationRef.id };
});

// Get user conversations
export const getConversations = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { limit = 20 } = data;

  const snapshot = await admin.firestore()
    .collection('conversations')
    .where('userId', '==', userId)
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();

  const conversations = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
  }));

  return { conversations };
});

// Delete conversation
export const deleteConversation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { conversationId } = data;

  const conversationRef = admin.firestore()
    .collection('conversations')
    .doc(conversationId);

  const doc = await conversationRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', 'Conversation not found');
  }

  if (doc.data()?.userId !== userId) {
    throw new functions.https.HttpsError('permission-denied', 'Not authorized');
  }

  await conversationRef.delete();

  return { success: true };
});
