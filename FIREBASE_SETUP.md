# Firebase Configuration Setup

This document outlines how to configure Firebase for the Synther Holographic Pro application. The project uses compile-time environment variables (via `--dart-define`) for Flutter app Firebase settings and Firebase environment configuration for Cloud Functions.

## 1. Flutter App Firebase Configuration (Client-Side)

### 1.1. Create Your `.env` File

In the root directory of the project, you will find a file named `.env.example`. This file serves as a template for your actual Firebase configuration for the Flutter app.

1.  **Copy the template:** Make a copy of `.env.example` and rename the copy to `.env`.
    ```bash
    cp .env.example .env
    ```
2.  **Gitignore:** The `.env` file (containing your actual keys) should **not** be committed to version control. Ensure that `.env` is listed in your project's `.gitignore` file.

### 1.2. Populate Your `.env` File

Open your newly created `.env` file with a text editor. Replace placeholder values (e.g., `YOUR_API_KEY_HERE`) with values from your Firebase project.

**(Refer to the content of `.env.example` for the list of variables like `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, platform-specific `FIREBASE_APP_ID_...`, etc. The `.env.example` file should be updated by your team to be comprehensive if it's currently minimal.)**

**Where to find these values:**
*   Go to the [Firebase Console](https://console.firebase.google.com/).
*   Select your project.
*   Navigate to **Project settings** (gear icon ⚙️).
*   In the **General** tab, under "Your apps", select each app (Web, Android, iOS) to find its specific `App ID` and other relevant values like `API Key`, `Project ID`, `Messaging Sender ID`, `Auth Domain`, `Storage Bucket`.
*   For Web apps, find the `Measurement ID` under the "Your apps" card in the SDK setup snippet if Google Analytics is enabled.
*   For iOS apps, ensure the `Bundle ID` in Firebase matches your Xcode project.

### 1.3. Running or Building Your Flutter App

The application's `lib/firebase_options.dart` reads these settings via `String.fromEnvironment`. Pass them using `--dart-define`:

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=YOUR_ACTUAL_API_KEY \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_ACTUAL_PROJECT_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_ACTUAL_MESSAGING_SENDER_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_ACTUAL_AUTH_DOMAIN \
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_ACTUAL_STORAGE_BUCKET \
  --dart-define=FIREBASE_APP_ID_WEB=YOUR_ACTUAL_WEB_APP_ID \
  --dart-define=FIREBASE_APP_ID_ANDROID=YOUR_ACTUAL_ANDROID_APP_ID \
  --dart-define=FIREBASE_APP_ID_IOS=YOUR_ACTUAL_IOS_APP_ID \
  --dart-define=FIREBASE_APP_ID_LINUX=YOUR_ACTUAL_LINUX_APP_ID \
  --dart-define=FIREBASE_APP_ID=YOUR_ACTUAL_FALLBACK_APP_ID \
  --dart-define=FIREBASE_MEASUREMENT_ID=YOUR_ACTUAL_MEASUREMENT_ID \
  --dart-define=FIREBASE_IOS_BUNDLE_ID=YOUR_ACTUAL_IOS_BUNDLE_ID
  # Add --dart-define flags for any other environment variables defined in your .env like HUGGING_FACE_API_KEY etc.
```
Apply the same for `flutter build` commands. Configure your IDE's launch settings (e.g., `launch.json` in VS Code or "Additional run args" in Android Studio) for convenience.

## 2. Firebase Cloud Functions Setup & Deployment (Backend)

The project includes Firebase Cloud Functions (in the `functions` directory) for features like AI Preset Generation using OpenAI.

### 2.1. Prerequisites:

1.  **Node.js and npm:** Ensure Node.js (version 18 as specified in `functions/package.json`) and npm are installed.
2.  **Firebase CLI:** Be logged in (`firebase login`) and have your project selected (`firebase use YOUR_PROJECT_ID`).
3.  **Install Dependencies:** From the project root, run:
    ```bash
    cd functions
    npm install
    cd ..
    ```

### 2.2. Environment Configuration for Cloud Functions (API Keys):

Cloud Functions access API keys (e.g., for OpenAI) via Firebase environment configuration. **Do not hardcode API keys.** The `functions/src/index.ts` code currently uses `process.env.OPENAI_API_KEY`.

1.  **Set Environment Variable for OpenAI API Key:**
    To make `process.env.OPENAI_API_KEY` available to your deployed functions, set a Firebase environment configuration variable. The Firebase CLI often transforms config names (e.g., `group.keyname` becomes `GROUP_KEYNAME`). For `OPENAI_API_KEY` to be directly available as `process.env.OPENAI_API_KEY`, the most reliable way is often to set a non-dotted variable name if your runtime supports it, or adjust the access in code to use `functions.config()`.

    A common approach for setting variables that become `process.env.VAR_NAME` is:
    ```bash
    firebase functions:config:set openai_api_key="YOUR_OPENAI_API_KEY_HERE"
    ```
    Firebase Functions runtimes (especially newer Node.js versions) often automatically load variables set this way into `process.env` (e.g., `openai_api_key` might become `process.env.OPENAI_API_KEY`). Verify this with your specific Firebase project setup or by checking logs.

    Alternatively, to use Firebase's traditional structured configuration and access it via `functions.config()`:
    ```bash
    firebase functions:config:set openai.key="YOUR_OPENAI_API_KEY_HERE"
    ```
    Then, in `functions/src/index.ts`, you would access it as:
    `const apiKey = functions.config().openai.key;` (This would require a code change in `index.ts`).

    **Recommendation:** Stick with the current code `process.env.OPENAI_API_KEY`. Set the config using:
    ```bash
    firebase functions:config:set openai_api_key="YOUR_OPENAI_API_KEY_HERE"
    ```
    And verify after deployment if `process.env.OPENAI_API_KEY` is populated. If not, you may need to adjust the variable name in `index.ts` to match how Firebase populates `process.env` (e.g., `process.env.OPENAI_API_KEY` if you set `openai_api_key`) or use `functions.config()`. The key is that the deployed function must be able to access this key.

2.  **Viewing and Unsetting Configuration:**
    *   View: `firebase functions:config:get`
    *   Unset: `firebase functions:config:unset openai_api_key` (or the specific key you used, like `openai.key`)

### 2.3. Deploying Cloud Functions:

1.  **Build TypeScript (Usually handled by deploy command but good practice):**
    ```bash
    cd functions
    npm run build
    cd ..
    ```
2.  **Deploy:**
    From the project root directory:
    ```bash
    firebase deploy --only functions
    ```

### 2.4. Local Emulation:

1.  Ensure Emulator Suite is installed (`firebase setup:emulators:functions`).
2.  For local emulation, Firebase emulators can use the configuration set by `firebase functions:config:set`.
3.  If `process.env.OPENAI_API_KEY` isn't picked up directly from the cloud config by the emulator, you can:
    *   Set it in your shell before running the emulator: `OPENAI_API_KEY="your_local_key" firebase emulators:start --only functions` (from within the `functions` directory or project root).
    *   Or, create a `.env` file (e.g., `functions/.env`) with `OPENAI_API_KEY=your_local_key` and use the `dotenv` package in a local-only section of your `index.ts` or a wrapper script if you need `process.env` populated for local tests without relying on cloud config. The simplest for emulation is often setting it in the shell or ensuring your `firebase emulators:start` command loads it from a runtime config file (e.g., `firebase functions:config:get > .runtimeconfig.json` then `firebase emulators:start --import=./functions_emulator_data --only functions`). The `firebase emulators:start` command should ideally load the cloud config automatically.
