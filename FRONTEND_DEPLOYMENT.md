# Frontend Deployment Guide

Complete guide to deploying the Next.js frontend for the Upstate AI Portal.

## 📋 Prerequisites

1. **Firebase Backend Deployed** - Follow [FIREBASE_DEPLOYMENT.md](FIREBASE_DEPLOYMENT.md) first
2. **Node.js 18+** installed
3. **Firebase project created** with hosting enabled

---

## 🚀 Local Development Setup

### Step 1: Install Dependencies

```bash
cd frontend
npm install
```

### Step 2: Configure Environment Variables

Create `.env.local` file:

```bash
cp .env.example .env.local
```

Edit `.env.local` with your Firebase config (from Firebase Console → Project Settings → General → Your apps):

```env
NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSy...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=upstate-ai-portal.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=upstate-ai-portal
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=upstate-ai-portal.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:abcdef
```

### Step 3: Run Development Server

```bash
npm run dev
```

Open http://localhost:3000

---

## 🎨 Features

### Authentication
- ✅ Email/Password login and signup
- ✅ Google Sign-in
- ✅ Role selection (Clinician, Billing, Admin, Developer)
- ✅ Protected routes with AuthGuard

### Chat Interface
- ✅ Multi-model AI chat (Claude, GPT, Gemini)
- ✅ Model selector with pricing information
- ✅ Real-time chat with markdown support
- ✅ Code syntax highlighting
- ✅ Conversation history

### Usage Tracking
- ✅ Real-time cost monitoring
- ✅ Token usage statistics
- ✅ Rate limit display (100 requests/hour)
- ✅ Usage history

### Supported Models

| Model | Provider | Best For | Cost |
|-------|----------|----------|------|
| Claude 3.5 Sonnet | Anthropic | Complex reasoning | $3-15/1M tokens |
| Claude 3 Opus | Anthropic | Max intelligence | $15-75/1M tokens |
| Claude 3 Haiku | Anthropic | Speed & cost | $0.25-1.25/1M tokens |
| GPT-4 Turbo | OpenAI | General purpose | $10-30/1M tokens |
| GPT-4 | OpenAI | Advanced tasks | $30-60/1M tokens |
| GPT-3.5 Turbo | OpenAI | Fast & cheap | $0.5-1.5/1M tokens |
| Gemini Pro | Google | Google integration | $0.5-1.5/1M tokens |

---

## 📦 Build for Production

### Option 1: Deploy to Firebase Hosting (Recommended)

```bash
# Build Next.js app
npm run build

# The output will be in 'out' directory

# Deploy to Firebase (from project root)
cd ..
firebase deploy --only hosting
```

Your app will be live at: `https://upstate-ai-portal.web.app`

### Option 2: Deploy to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd frontend
vercel

# Follow prompts and add environment variables
```

### Option 3: Deploy to Netlify

```bash
# Build
npm run build

# Deploy via Netlify CLI or drag & drop 'out' folder to netlify.com
```

---

## 🔧 Configuration

### Update Firebase Config After Deployment

1. Go to Firebase Console → Authentication → Settings
2. Add your deployment URL to **Authorized domains**:
   - `upstate-ai-portal.web.app` (Firebase Hosting)
   - `your-custom-domain.com` (if using custom domain)

### Enable Google Sign-in

1. Firebase Console → Authentication → Sign-in method
2. Enable **Google** provider
3. Add your support email

---

## 🎨 Customization

### Change Theme Colors

Edit `frontend/tailwind.config.ts`:

```typescript
colors: {
  primary: {
    50: '#your-color',
    // ... other shades
  },
}
```

### Add New Models

Models are fetched from Cloud Functions. To add/remove models, edit:
`functions/src/index.ts` → `getModels` function

### Modify Rate Limits

Edit `functions/src/index.ts`:

```typescript
if (data.requestCount >= 100) { // Change this number
  // ...
}
```

---

## 🐛 Troubleshooting

### "Firebase not configured" Error

**Fix:** Make sure `.env.local` has all Firebase config values:
```bash
cat .env.local  # Check all values are set
```

### Authentication Not Working

**Fixes:**
1. Check Firebase Console → Authentication is enabled
2. Verify authorized domains include your deployment URL
3. Clear browser cache and cookies

### Chat Function Fails

**Fixes:**
1. Verify Cloud Functions are deployed:
   ```bash
   firebase functions:list
   ```
2. Check function logs:
   ```bash
   firebase functions:log
   ```
3. Ensure API keys are set:
   ```bash
   firebase functions:config:get
   ```

### Build Errors

```bash
# Clear cache and reinstall
rm -rf node_modules .next
npm install
npm run build
```

---

##🚀 Performance Optimization

### 1. Enable Code Splitting

Already configured with Next.js dynamic imports.

### 2. Add Service Worker (Optional)

For offline support, add PWA configuration.

### 3. Image Optimization

Use Next.js Image component for profile pictures:

```typescript
import Image from 'next/image';

<Image src="/profile.jpg" width={40} height={40} alt="Profile" />
```

---

## 📱 Mobile Responsiveness

The UI is fully responsive and works on:
- ✅ Desktop (1920x1080+)
- ✅ Tablet (768x1024)
- ✅ Mobile (375x667+)

Test with:
```bash
npm run dev
# Then open DevTools → Toggle device toolbar
```

---

## 🔒 Security Best Practices

### 1. Environment Variables

Never commit `.env.local`:
```bash
# Already in .gitignore
.env.local
.env*.local
```

### 2. Firebase Security Rules

Already configured in `firestore.rules` and `storage.rules`.

### 3. Rate Limiting

Implemented server-side in Cloud Functions (100 requests/hour).

---

## 📊 Analytics (Optional)

### Add Google Analytics

1. Enable in Firebase Console → Analytics
2. Add to `next.config.js`:

```javascript
const nextConfig = {
  // ...
  env: {
    NEXT_PUBLIC_GA_ID: process.env.NEXT_PUBLIC_GA_ID,
  },
}
```

3. Track events:

```typescript
import { logEvent } from 'firebase/analytics';

logEvent(analytics, 'chat_sent', {
  model: selectedModel,
});
```

---

## 🎯 Next Features to Add

### 1. Conversation History
- Save and load past chats
- Search conversations
- Export conversations

### 2. RAG (Document Upload)
- Upload PDFs for context
- Search through documents
- Cite sources in responses

### 3. Streaming Responses
- Real-time token streaming
- Better UX for long responses

### 4. Team Features
- Share conversations
- Collaborate on prompts
- Team usage dashboards

### 5. Voice Input
- Speech-to-text
- Voice commands
- Audio responses

---

## 📝 File Structure

```
frontend/
├── src/
│   ├── app/
│   │   ├── page.tsx              # Home (redirects)
│   │   ├── login/
│   │   │   └── page.tsx          # Login/Signup page
│   │   ├── dashboard/
│   │   │   └── page.tsx          # Main chat interface
│   │   ├── layout.tsx            # Root layout
│   │   └── globals.css           # Global styles
│   │
│   ├── components/
│   │   └── AuthGuard.tsx         # Protected route wrapper
│   │
│   └── lib/
│       ├── firebase.ts           # Firebase configuration
│       └── ai.ts                 # AI API helpers
│
├── public/                        # Static assets
├── package.json
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
└── .env.example
```

---

## ✅ Deployment Checklist

Before going live:

- [ ] Firebase backend deployed
- [ ] Environment variables configured
- [ ] Firebase Authentication enabled
- [ ] Firestore rules deployed
- [ ] Cloud Functions working
- [ ] Frontend built successfully
- [ ] Deployed to hosting
- [ ] Custom domain configured (optional)
- [ ] SSL certificate active
- [ ] Authorized domains updated
- [ ] Test login works
- [ ] Test chat works
- [ ] Test all AI models
- [ ] Usage tracking works
- [ ] Mobile responsive checked
- [ ] Cross-browser tested

---

## 🎉 You're Live!

Your Upstate AI Portal is now deployed and ready to use!

**Access your portal:**
- Firebase Hosting: `https://upstate-ai-portal.web.app`
- Custom domain: `https://your-domain.com` (if configured)

**Share with testers:**
1. Send them the URL
2. They create an account
3. They can start chatting with AI models

**Monitor usage:**
- Firebase Console → Functions → Dashboard
- Firebase Console → Authentication → Users
- Check costs daily during first week

---

## 💡 Tips

1. **Start with Claude Haiku** - Cheapest for testing
2. **Set Daily Budget** - Monitor Firebase costs
3. **Test Thoroughly** - Try all models before sharing
4. **Gather Feedback** - Ask testers what they need
5. **Iterate Quickly** - Firebase makes updates easy

---

## 📞 Support

- **Frontend Issues:** Check browser console (F12)
- **Backend Issues:** `firebase functions:log`
- **Build Issues:** Clear `.next` and `node_modules`
- **Auth Issues:** Check Firebase Console → Authentication

---

**Your multi-model AI portal is ready! 🚀**

Cost-effective, scalable, and beautiful UI with 7 AI models to choose from.
