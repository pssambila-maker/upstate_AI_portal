# Firebase MVP Deployment Guide

Complete guide to deploying the Upstate AI Portal on Firebase with multi-model AI support (Claude, GPT, Gemini).

## 📋 Prerequisites

### 1. Create Firebase Account
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Sign in with your Google account
3. Click "Add Project"
4. Name: `upstate-ai-portal`
5. Disable Google Analytics (optional for MVP)
6. Click "Create Project"

### 2. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 3. Get API Keys

#### Anthropic Claude (Required)
1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Sign up / Log in
3. Navigate to "API Keys"
4. Click "Create Key"
5. Copy the key (starts with `sk-ant-`)

#### OpenAI (Optional)
1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign up / Log in
3. Click "Create new secret key"
4. Copy the key (starts with `sk-`)

#### Google AI (Optional)
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with Google account
3. Click "Get API Key"
4. Copy the key

---

## 🚀 Step-by-Step Deployment

### Step 1: Clone/Navigate to Project
```bash
cd d:\AI_HealthCare\Upstate_AI_portal
```

### Step 2: Login to Firebase
```bash
firebase login
```

This will open a browser window for authentication.

### Step 3: Initialize Firebase Project
```bash
# Link to your Firebase project
firebase use upstate-ai-portal

# Or create a new project from CLI
firebase projects:create upstate-ai-portal
```

### Step 4: Enable Firebase Services

```bash
# Enable Firestore
firebase firestore:databases:create --location=us-east1

# Enable Authentication
firebase auth:export --format=json auth.json

# Enable Storage
firebase storage:buckets:create gs://upstate-ai-portal.appspot.com
```

Or enable via [Firebase Console](https://console.firebase.google.com/):
1. Go to your project
2. **Authentication** → Get Started → Enable **Email/Password** and **Google**
3. **Firestore Database** → Create Database → Start in **production mode** → Choose location **us-east1**
4. **Storage** → Get Started → Start in **production mode**

### Step 5: Upgrade to Blaze Plan (Required for Cloud Functions)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click Settings (gear icon) → Usage and Billing
4. Click "Modify plan"
5. Select "Blaze - Pay as you go"
6. Add payment method

**Don't worry:** Free tier is very generous. You likely won't be charged for MVP usage.

### Step 6: Set Environment Variables for Functions

```bash
# Navigate to functions directory
cd functions

# Set Anthropic API key
firebase functions:config:set anthropic.api_key="sk-ant-YOUR_KEY_HERE"

# Set OpenAI API key (optional)
firebase functions:config:set openai.api_key="sk-YOUR_KEY_HERE"

# Set Google API key (optional)
firebase functions:config:set google.api_key="YOUR_KEY_HERE"

# View current config
firebase functions:config:get
```

### Step 7: Install Function Dependencies

```bash
# Still in functions directory
npm install
```

### Step 8: Deploy Cloud Functions

```bash
# Build TypeScript
npm run build

# Deploy functions
firebase deploy --only functions
```

This will deploy:
- `chat` - Main AI chat function (supports Claude, GPT, Gemini)
- `getModels` - Get available models
- `getUsage` - Get usage statistics
- `saveConversation` - Save conversations
- `getConversations` - Retrieve conversations
- `deleteConversation` - Delete conversations

### Step 9: Deploy Firestore Security Rules

```bash
# From project root
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### Step 10: Initialize Database

You can manually add initial data via Firebase Console or use this script:

```javascript
// Initialize models collection
const models = [
  {
    id: 'claude-3-5-sonnet-20241022',
    name: 'Claude 3.5 Sonnet',
    provider: 'Anthropic',
    enabled: true,
  },
  // Add other models...
];

// Run in Firebase Console → Firestore → Add documents
```

---

## 🧪 Testing Your Deployment

### Test Cloud Functions Locally

```bash
# Start Firebase emulators
cd d:\AI_HealthCare\Upstate_AI_portal
firebase emulators:start
```

This starts:
- Functions: http://localhost:5001
- Firestore: http://localhost:8080
- Hosting: http://localhost:5000
- Emulator UI: http://localhost:4000

### Test Chat Function

```javascript
// In your frontend or test script
const functions = getFunctions();
const chat = httpsCallable(functions, 'chat');

const result = await chat({
  model: 'claude-3-5-sonnet-20241022',
  messages: [
    { role: 'user', content: 'Hello!' }
  ],
  maxTokens: 100,
  temperature: 0.7
});

console.log(result.data.content);
```

### Test via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to **Functions**
3. Click on `chat` function
4. Click "Logs" tab to see invocation logs

---

## 💰 Cost Monitoring

### Set Budget Alerts

1. Firebase Console → Settings → Usage and Billing
2. Click "Details & Settings"
3. Click "Set Budget & Alerts"
4. Set budget: $50/month
5. Set alert thresholds: 50%, 90%, 100%

### Monitor Usage

```bash
# View function invocations
firebase functions:log

# View Firestore usage
# Go to Console → Firestore → Usage tab
```

### Estimated Costs (First Month)

| Service | Free Tier | Estimated Cost |
|---------|-----------|----------------|
| Cloud Functions | 2M invocations | $0 (within free tier) |
| Firestore | 50K reads/day | $0-5 |
| Storage | 5GB | $0 (within free tier) |
| Hosting | 10GB | $0 (within free tier) |
| **AI APIs** | | |
| Anthropic Claude | Pay per use | $30-80 |
| OpenAI GPT | Pay per use | $20-50 (if used) |
| Google Gemini | Pay per use | $5-15 (if used) |
| **Total** | | **$30-150/month** |

---

## 🔒 Security Setup

### 1. Enable App Check (Optional but Recommended)

Prevents abuse of your Cloud Functions:

```bash
# Enable App Check
firebase appcheck:enable

# Get your web app ID
firebase apps:list
```

Then in Firebase Console:
1. Go to App Check
2. Register your web app
3. Choose reCAPTCHA provider
4. Enable enforcement for Cloud Functions

### 2. Set Up User Roles

When users sign up, assign roles in Firestore:

```javascript
// After user signs up
await setDoc(doc(db, 'users', user.uid), {
  email: user.email,
  role: 'clinician',  // or 'billing', 'admin', 'developer'
  createdAt: serverTimestamp(),
});
```

### 3. Configure CORS (if needed)

```bash
# In functions/src/index.ts
import * as cors from 'cors';
const corsHandler = cors({ origin: true });

export const myFunction = functions.https.onRequest((req, res) => {
  corsHandler(req, res, () => {
    // Your function logic
  });
});
```

---

## 🎨 Frontend Integration

### Option 1: Test with Simple HTML (Quick Start)

Create `public/test.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Upstate AI Test</title>
  <script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-auth-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-functions-compat.js"></script>
</head>
<body>
  <h1>Test Chat</h1>
  <button onclick="testChat()">Send Test Message</button>
  <div id="response"></div>

  <script>
    // Your Firebase config (from Firebase Console)
    const firebaseConfig = {
      apiKey: "YOUR_API_KEY",
      authDomain: "upstate-ai-portal.firebaseapp.com",
      projectId: "upstate-ai-portal",
      storageBucket: "upstate-ai-portal.appspot.com",
      messagingSenderId: "YOUR_ID",
      appId: "YOUR_APP_ID"
    };

    firebase.initializeApp(firebaseConfig);

    async function testChat() {
      // Sign in anonymously for testing
      await firebase.auth().signInAnonymously();

      const chat = firebase.functions().httpsCallable('chat');
      const result = await chat({
        model: 'claude-3-5-sonnet-20241022',
        messages: [{ role: 'user', content: 'Hello!' }],
        maxTokens: 100
      });

      document.getElementById('response').innerText = result.data.content;
    }
  </script>
</body>
</html>
```

Deploy:
```bash
firebase deploy --only hosting
```

Access at: `https://upstate-ai-portal.web.app/test.html`

### Option 2: Full Next.js Frontend (Recommended)

I can create the full Next.js frontend separately with:
- Firebase Authentication UI
- Model selector
- Chat interface
- Usage dashboard
- Conversation history

---

## 📱 Next Steps

### 1. Add Your First User

Firebase Console → Authentication → Add User:
- Email: your@email.com
- Password: (create password)

### 2. Test the Chat Function

Use the test HTML above or call from your app.

### 3. Monitor Costs

Check Firebase Console → Usage and Billing daily for first week.

### 4. Share with Testers

Give them the URL: `https://upstate-ai-portal.web.app`

---

## 🐛 Troubleshooting

### Functions Not Deploying

```bash
# Check Node version (should be 18)
node --version

# Reinstall dependencies
cd functions
rm -rf node_modules package-lock.json
npm install

# Try deploying one function at a time
firebase deploy --only functions:chat
```

### Authentication Errors

```bash
# Check if auth is enabled
firebase auth:export test.json

# If empty, enable in Console:
# Authentication → Get Started → Email/Password
```

### API Key Errors

```bash
# Verify environment variables are set
firebase functions:config:get

# Update if needed
firebase functions:config:set anthropic.api_key="NEW_KEY"

# Redeploy functions
firebase deploy --only functions
```

### CORS Errors

Add to `functions/src/index.ts`:
```typescript
export const chat = functions.https.onCall(...)
// onCall functions automatically handle CORS
```

---

## 💡 Cost Optimization Tips

1. **Use Claude Haiku for Simple Tasks** - 10x cheaper than Sonnet
2. **Set Max Tokens Limits** - Prevents runaway costs
3. **Enable Firestore Caching** - Reduce database reads
4. **Use Firebase Emulators** - Test locally before deploying
5. **Monitor Usage Daily** - Catch issues early

---

## 📞 Support

If you encounter issues:

1. Check [Firebase Documentation](https://firebase.google.com/docs)
2. Check [Anthropic Documentation](https://docs.anthropic.com/)
3. View Firebase Console → Functions → Logs
4. Check GitHub issues

---

## ✅ Deployment Checklist

- [ ] Firebase project created
- [ ] Blaze plan enabled
- [ ] Anthropic API key obtained
- [ ] Environment variables set
- [ ] Cloud Functions deployed
- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] Authentication enabled
- [ ] Test user created
- [ ] Budget alerts configured
- [ ] Test chat function works
- [ ] Frontend deployed (or test page)
- [ ] Shared with first testers

**Congratulations! Your Firebase MVP is live! 🎉**
