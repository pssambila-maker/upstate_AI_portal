# Upstate AI Portal - Firebase MVP

Multi-model AI chat portal deployed on Firebase with support for Claude, GPT, and Gemini models.

## 🚀 Quick Start (5 Minutes)

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Get API Keys

**Anthropic Claude (Required):**
- Sign up at: https://console.anthropic.com/
- Create API key
- Copy key (starts with `sk-ant-`)

### 3. Deploy to Firebase

```bash
# Login to Firebase
firebase login

# Deploy functions
cd functions
npm install
firebase functions:config:set anthropic.api_key="sk-ant-YOUR_KEY"
npm run build
firebase deploy --only functions

# Deploy security rules
cd ..
firebase deploy --only firestore:rules,storage:rules
```

### 4. Enable Firebase Services

Go to [Firebase Console](https://console.firebase.google.com/):
1. **Authentication** → Enable Email/Password
2. **Firestore** → Create database (us-east1)
3. **Upgrade to Blaze Plan** (required for Cloud Functions)

### 5. Test It!

Create a test user and call the chat function:

```javascript
const chat = httpsCallable(functions, 'chat');
const result = await chat({
  model: 'claude-3-5-sonnet-20241022',
  messages: [{ role: 'user', content: 'Hello!' }]
});
console.log(result.data.content);
```

---

## 💰 Costs

**Free Tier Includes:**
- 2M Cloud Function invocations/month
- 50K Firestore reads/day
- 5GB storage
- 10GB hosting bandwidth

**Estimated Monthly Cost:**
- Firebase: $0-10 (likely free)
- Anthropic Claude: $30-100 (usage-based)
- **Total: $30-110/month**

---

## 🎯 Features

### Supported AI Models

**Anthropic Claude:**
- claude-3-5-sonnet-20241022 (Best overall)
- claude-3-opus-20240229 (Most powerful)
- claude-3-haiku-20240307 (Fastest, cheapest)

**OpenAI GPT:**
- gpt-4-turbo
- gpt-4
- gpt-3.5-turbo

**Google Gemini:**
- gemini-pro

### Cloud Functions

1. **chat** - Send messages to any AI model
2. **getModels** - List available models with pricing
3. **getUsage** - Track token usage and costs
4. **saveConversation** - Save chat history
5. **getConversations** - Retrieve past chats
6. **deleteConversation** - Delete chat history

### Built-in Features

- ✅ Multi-model AI routing
- ✅ Rate limiting (100 requests/hour per user)
- ✅ Usage tracking and cost monitoring
- ✅ Conversation history
- ✅ User authentication
- ✅ Role-based access (clinician, billing, admin, developer)
- ✅ Firestore security rules
- ✅ Real-time cost calculation

---

## 📂 Project Structure

```
upstate_AI_portal/
├── firebase.json           # Firebase configuration
├── .firebaserc            # Firebase project settings
├── firestore.rules        # Database security rules
├── firestore.indexes.json # Database indexes
├── storage.rules          # Storage security rules
│
├── functions/             # Cloud Functions (TypeScript)
│   ├── src/
│   │   └── index.ts      # Main functions (chat, getModels, etc.)
│   ├── package.json
│   └── tsconfig.json
│
├── FIREBASE_DEPLOYMENT.md # Detailed deployment guide
└── FIREBASE_README.md    # This file
```

---

## 🔧 Configuration

### Add More API Keys

```bash
# OpenAI (optional)
firebase functions:config:set openai.api_key="sk-YOUR_KEY"

# Google AI (optional)
firebase functions:config:set google.api_key="YOUR_KEY"

# Redeploy
firebase deploy --only functions
```

### Modify Rate Limits

Edit `functions/src/index.ts`:

```typescript
// Change from 100 to your desired limit
if (data.requestCount >= 100) {
  throw new functions.https.HttpsError(...);
}
```

---

## 📊 Monitoring

### View Logs

```bash
# Real-time logs
firebase functions:log

# Logs for specific function
firebase functions:log --only chat
```

### Check Usage

Firebase Console → Functions → Dashboard

### Set Budget Alerts

Firebase Console → Settings → Usage and Billing → Set Budget

---

## 🔒 Security

### Firestore Rules

All data is protected by authentication:
- Users can only read/write their own data
- Admins can access all data
- Usage tracking is server-side only

### Environment Variables

Never commit API keys! They are stored in Firebase config:

```bash
# View config (safe to run)
firebase functions:config:get

# Never commit .env files or hardcode keys
```

---

## 🧪 Testing

### Local Testing with Emulators

```bash
# Start emulators
firebase emulators:start

# Access emulator UI
open http://localhost:4000
```

Test your functions locally before deploying!

---

## 📱 Frontend Integration

### Initialize Firebase in Your App

```typescript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFunctions, httpsCallable } from 'firebase/functions';

const firebaseConfig = {
  // Get from Firebase Console → Project Settings
  apiKey: "YOUR_API_KEY",
  authDomain: "upstate-ai-portal.firebaseapp.com",
  projectId: "upstate-ai-portal",
  // ...
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const functions = getFunctions(app);
```

### Call Chat Function

```typescript
const chat = httpsCallable(functions, 'chat');

const response = await chat({
  model: 'claude-3-5-sonnet-20241022',
  messages: [
    { role: 'user', content: 'What is HIPAA?' }
  ],
  maxTokens: 500,
  temperature: 0.7
});

console.log(response.data.content);
```

---

## 🚀 Next Steps

1. **Deploy Frontend** - Create React/Next.js UI
2. **Add More Features** - RAG, function calling, streaming
3. **Customize Models** - Add/remove models as needed
4. **Scale Up** - Monitor usage and optimize costs
5. **Go Production** - Move to company Azure when ready

---

## 📞 Need Help?

- **Detailed Guide:** See [FIREBASE_DEPLOYMENT.md](FIREBASE_DEPLOYMENT.md)
- **Firebase Docs:** https://firebase.google.com/docs
- **Anthropic Docs:** https://docs.anthropic.com/
- **OpenAI Docs:** https://platform.openai.com/docs

---

## 💡 Tips

1. **Start with Claude Haiku** - Cheapest model for testing
2. **Monitor Costs Daily** - Check Firebase Console
3. **Use Emulators** - Test locally to save money
4. **Set Max Tokens** - Prevent expensive requests
5. **Enable Caching** - Reduce redundant API calls

---

**Your Firebase AI Portal is ready! 🎉**

Cost-effective, scalable, and supports multiple AI models.
