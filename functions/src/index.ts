import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { OpenAI } from 'openai';
import * as cors from 'cors';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize OpenAI with API key from environment
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// CORS configuration
const corsHandler = cors({ origin: true });

// Firestore database reference
const db = admin.firestore();

/**
 * Generate AI-powered synthesizer preset using OpenAI GPT-4
 */
export const generatePreset = functions.https.onCall(async (data, context) => {
  const { description, userId } = data;
  
  // Validate input
  if (!description || typeof description !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Description is required and must be a string'
    );
  }
  
  try {
    // Advanced prompt for professional sound design
    const systemPrompt = `You are a professional sound designer and synthesizer programmer with expertise in electronic music production.

Generate detailed synthesizer parameters for the following sound description. Return a JSON object with these exact parameter ranges:

{
  "oscillators": [
    {
      "type": "sine|square|sawtooth|triangle|noise",
      "frequency": 0.0-1.0,
      "detune": 0.0-1.0,
      "volume": 0.0-1.0,
      "pan": 0.0-1.0
    }
  ],
  "filter": {
    "type": "lowpass|highpass|bandpass",
    "cutoff": 0.0-1.0,
    "resonance": 0.0-1.0,
    "envelope": 0.0-1.0
  },
  "envelope": {
    "attack": 0.0-1.0,
    "decay": 0.0-1.0,
    "sustain": 0.0-1.0,
    "release": 0.0-1.0
  },
  "effects": {
    "reverb": 0.0-1.0,
    "delay": 0.0-1.0,
    "chorus": 0.0-1.0,
    "distortion": 0.0-1.0
  },
  "lfo": {
    "rate": 0.0-1.0,
    "amount": 0.0-1.0,
    "destination": "cutoff|volume|pitch"
  }
}

Consider:
- Musical context and genre
- Harmonic content and timbre
- Dynamic characteristics
- Spatial effects and movement
- Professional production quality`;

    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: `Create a synthesizer preset for: "${description}"` }
      ],
      temperature: 0.7,
      max_tokens: 1000,
    });
    
    const generatedContent = response.choices[0].message.content;
    if (!generatedContent) {
      throw new Error('No content generated from OpenAI');
    }
    
    // Parse the JSON response
    const presetData = JSON.parse(generatedContent);
    
    // Add metadata
    const preset = {
      ...presetData,
      metadata: {
        description,
        generatedAt: new Date().toISOString(),
        model: "gpt-4",
        userId: userId || null,
      }
    };
    
    // Save to Firestore if user is authenticated
    if (userId) {
      await db.collection('ai_presets').add({
        preset,
        description,
        userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    
    // Log for analytics
    await db.collection('analytics').add({
      event: 'ai_preset_generated',
      description,
      userId: userId || 'anonymous',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    return { preset, success: true };
    
  } catch (error) {
    console.error('Error generating preset:', error);
    
    // Log error for debugging
    await db.collection('errors').add({
      function: 'generatePreset',
      error: error.toString(),
      description,
      userId: userId || 'anonymous',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate preset. Please try again.'
    );
  }
});

/**
 * Analyze sound description for better preset generation
 */
export const analyzeDescription = functions.https.onCall(async (data, context) => {
  const { description } = data;
  
  if (!description || typeof description !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Description is required and must be a string'
    );
  }
  
  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `Analyze the following sound description and extract:
1. Genre/style indicators
2. Emotional characteristics
3. Technical requirements
4. Suggested parameter focus areas
5. Musical context

Return a JSON object with analysis results.`
        },
        {
          role: "user",
          content: description
        }
      ],
      temperature: 0.3,
      max_tokens: 500,
    });
    
    const analysis = response.choices[0].message.content;
    
    return {
      analysis: JSON.parse(analysis || '{}'),
      success: true
    };
    
  } catch (error) {
    console.error('Error analyzing description:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to analyze description'
    );
  }
});

/**
 * Get trending presets based on likes and recent activity
 */
export const getTrendingPresets = functions.https.onCall(async (data, context) => {
  try {
    const { limit = 20 } = data;
    
    // Get presets with high engagement in the last 7 days
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    
    const trending = await db.collection('presets')
      .where('isPublic', '==', true)
      .where('createdAt', '>=', weekAgo)
      .orderBy('likes', 'desc')
      .limit(limit)
      .get();
    
    const presets = trending.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    return { presets, success: true };
    
  } catch (error) {
    console.error('Error getting trending presets:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get trending presets'
    );
  }
});

/**
 * Batch process multiple preset operations
 */
export const batchPresetOperations = functions.https.onCall(async (data, context) => {
  const { operations } = data;
  
  if (!Array.isArray(operations)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Operations must be an array'
    );
  }
  
  try {
    const results = await Promise.all(operations.map(async (op) => {
      switch (op.type) {
        case 'generate':
          return await generatePreset.run(op.data, context);
        case 'save':
          return await savePresetOperation(op.data);
        case 'analyze':
          return await analyzeDescription.run(op.data, context);
        default:
          throw new Error(`Unknown operation type: ${op.type}`);
      }
    }));
    
    return {
      results,
      batchId: admin.firestore.Timestamp.now().toMillis().toString(),
      success: true
    };
    
  } catch (error) {
    console.error('Error in batch operations:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to process batch operations'
    );
  }
});

/**
 * Helper function to save preset
 */
async function savePresetOperation(data: any) {
  const { preset, name, description, userId, isPublic = false } = data;
  
  const presetDoc = await db.collection('presets').add({
    name,
    description,
    parameters: preset,
    userId,
    isPublic,
    likes: 0,
    downloads: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  return { presetId: presetDoc.id, success: true };
}

/**
 * Update user statistics when presets are used
 */
export const updateUserStats = functions.firestore
  .document('sessions/{sessionId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // If session ended (endTime was added)
    if (!before.endTime && after.endTime && after.userId) {
      const duration = after.duration || 0;
      
      await db.collection('users').doc(after.userId).update({
        'statistics.sessionsPlayed': admin.firestore.FieldValue.increment(1),
        'statistics.totalPlayTime': admin.firestore.FieldValue.increment(duration),
        'statistics.lastSession': after.endTime,
      });
    }
  });

/**
 * Cleanup old analytics data (runs daily)
 */
export const cleanupAnalytics = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const oldAnalytics = await db.collection('analytics')
      .where('timestamp', '<=', thirtyDaysAgo)
      .get();
    
    const batch = db.batch();
    oldAnalytics.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`Cleaned up ${oldAnalytics.docs.length} old analytics records`);
  });