# 🔥 Firebase Setup Guide for Synther Holographic Pro

## Current Status: ⚠️ Configuration Required

The application is currently showing Firebase authentication errors because the API keys are not configured. This is expected for a new development environment.

## 🚀 Quick Setup (5 minutes)

### Step 1: Create/Access Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Either create a new project or use existing project: `synther-pro-holo`
3. Enable the following services:
   - **Authentication** (for user management)
   - **Firestore Database** (for presets and user data)
   - **Cloud Storage** (for audio samples and user files)
   - **Cloud Functions** (for LLM preset generation)

### Step 2: Get Configuration Values

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **"Your apps"** section
3. If no web app exists, click **"Add app"** > **Web** 
4. Copy the configuration values from the **Firebase SDK snippet**

### Step 3: Configure Environment Variables

1. Copy `.env.template` to `.env`:
   ```bash
   cp .env.template .env
   ```

2. Edit `.env` with your Firebase config values:
   ```env
   FIREBASE_PROJECT_ID=synther-pro-holo
   FIREBASE_API_KEY=AIzaSyB... # Your actual API key
   FIREBASE_AUTH_DOMAIN=synther-pro-holo.firebaseapp.com
   FIREBASE_STORAGE_BUCKET=synther-pro-holo.appspot.com
   FIREBASE_APP_ID_WEB=1:872646180221:web:c394d10b5b82696417a014
   FIREBASE_MESSAGING_SENDER_ID=872646180221
   FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX
   ```

### Step 4: Configure Firebase Services

#### Firestore Security Rules
Update `firestore.rules`:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read/write presets
    match /presets/{presetId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid);
    }
    
    // Public read access for shared content
    match /shared/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

#### Storage Security Rules
Update `storage.rules`:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User-specific files
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public samples and presets
    match /samples/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Step 5: Deploy Rules and Test

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules  
firebase deploy --only storage

# Test the app
flutter run -d chrome --web-port 3000
```

## 🎛️ Firebase Services Used by Synther

### Authentication
- **Purpose**: User accounts, session management
- **Providers**: Email/password, Google, anonymous
- **Current Status**: ❌ Needs API key configuration

### Firestore Database
- **Purpose**: User presets, settings, sharing
- **Collections**: 
  - `users/{userId}` - User profiles and settings
  - `presets/{presetId}` - Synthesizer presets
  - `shared/` - Community shared content
- **Current Status**: ❌ Needs rules deployment

### Cloud Storage
- **Purpose**: Audio samples, user recordings, preset data
- **Structure**:
  - `users/{userId}/` - Private user files
  - `samples/` - Public audio samples
  - `presets/` - Shared preset files
- **Current Status**: ❌ Needs rules deployment

### Cloud Functions
- **Purpose**: LLM preset generation, audio processing
- **Functions**:
  - `generatePreset` - AI-powered preset creation
  - `processAudio` - Server-side audio analysis
  - `sharePreset` - Community sharing logic
- **Current Status**: ⚠️ Functions exist but need deployment

## 🔧 Development vs Production

### Development Setup (Current)
- Use Firebase Emulators for local development
- No real Firebase project required for basic functionality
- Audio engine works without Firebase

### Production Setup (When Ready)
- Real Firebase project with production URLs
- Proper security rules and authentication
- Cloud Functions for advanced features

## 🚨 Current Error Resolution

The error `FirebaseError: Firebase: Error (auth/invalid-api-key)` will be resolved once you:

1. ✅ Create `.env` file with real Firebase config
2. ✅ Deploy security rules to Firebase project
3. ✅ Restart the Flutter development server

## 🧪 Testing Firebase Integration

Once configured, test these features:

1. **Authentication Flow**
   - Sign up with email/password
   - Google OAuth login
   - Anonymous sessions

2. **Preset Management**
   - Save synthesizer presets
   - Load saved presets
   - Share presets with community

3. **Cloud Features**
   - LLM preset generation
   - Community preset browsing
   - Audio sample management

## 📞 Support

If you encounter issues:

1. Check Firebase Console for error logs
2. Verify all environment variables are set
3. Ensure Firebase project has required services enabled
4. Check network connectivity and CORS settings

**Status: Ready for configuration with your Firebase project values**