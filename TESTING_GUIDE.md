# Upstate AI Portal - Testing Guide

## Live Application
**URL:** https://upstate-ai-portal.web.app

## Test Checklist

### 1. Authentication Testing (5 minutes)

#### Email/Password Sign Up
- [ ] Go to https://upstate-ai-portal.web.app
- [ ] Click "Sign up" toggle
- [ ] Enter test email (e.g., test@example.com)
- [ ] Enter password (min 6 characters)
- [ ] Select a role (Clinician, Billing, Admin, or Developer)
- [ ] Click "Sign Up"
- [ ] Verify you're redirected to /dashboard

#### Google Sign-In
- [ ] Log out from current session
- [ ] Click "Sign in with Google"
- [ ] Select Google account
- [ ] Verify you're redirected to /dashboard

#### Sign Out
- [ ] Click "Sign Out" button in dashboard
- [ ] Verify you're redirected to /login
- [ ] Verify you cannot access /dashboard without signing in

### 2. AI Chat Testing (10 minutes)

#### Test Claude Models
- [ ] Sign in to dashboard
- [ ] Select "Claude 3.5 Sonnet" from model dropdown
- [ ] Type: "Hello! Can you introduce yourself?"
- [ ] Verify response appears with markdown formatting
- [ ] Check usage panel shows token count and cost

#### Test GPT Models
- [ ] Select "GPT-4" or "GPT-4 Turbo" from dropdown
- [ ] Ask: "What are the benefits of AI in healthcare?"
- [ ] Verify response and usage tracking

#### Test Gemini Models
- [ ] Select "Gemini 1.5 Pro" from dropdown
- [ ] Ask: "Explain HIPAA compliance in simple terms"
- [ ] Verify response and cost calculation

### 3. Usage Tracking (5 minutes)

#### Check Usage Panel
- [ ] In dashboard, expand "Usage Statistics" panel
- [ ] Verify it shows:
  - Total tokens used (input + output)
  - Estimated cost in USD
  - Request count for current hour
- [ ] Send multiple messages
- [ ] Verify numbers update after each message

#### Rate Limiting Test
- [ ] Send messages rapidly (try to exceed 100 requests/hour)
- [ ] Verify rate limit error appears if exceeded
- [ ] Error should say: "Rate limit exceeded. Maximum 100 requests per hour."

### 4. Conversation Management (5 minutes)

#### Save Conversation
- [ ] Have a conversation with any model (3-5 messages)
- [ ] Note: Auto-save should work (check Firestore console)
- [ ] Verify conversation persists on page reload

#### Multiple Conversations
- [ ] Start a new conversation (clear current)
- [ ] Have a different conversation
- [ ] Check if both are saved (Firebase Console → Firestore)

### 5. UI/UX Testing (5 minutes)

#### Responsive Design
- [ ] Test on desktop (full width)
- [ ] Test on tablet (medium width)
- [ ] Test on mobile (narrow width)
- [ ] Verify layout adapts properly

#### Markdown Rendering
- [ ] Ask model: "Write a bullet list of 3 items"
- [ ] Verify bullets render correctly
- [ ] Ask: "Show me a code snippet in Python"
- [ ] Verify code block has proper formatting

#### Error Handling
- [ ] Disconnect internet
- [ ] Try sending a message
- [ ] Verify error message appears
- [ ] Reconnect internet and retry

### 6. Security Testing (5 minutes)

#### Protected Routes
- [ ] Log out completely
- [ ] Try accessing /dashboard directly
- [ ] Verify you're redirected to /login

#### Data Isolation
- [ ] Create two different user accounts
- [ ] Have conversations with each
- [ ] Verify users cannot see each other's data

### 7. Cost Monitoring (Ongoing)

#### Daily Checks (First Week)
- [ ] Check Firebase Console → Functions → Usage
- [ ] Review function invocation counts
- [ ] Check Firestore read/write operations
- [ ] Monitor actual costs vs estimates

#### API Cost Tracking
- [ ] Check Anthropic Console: https://console.anthropic.com/
- [ ] Review API usage and costs
- [ ] Check OpenAI Dashboard: https://platform.openai.com/usage
- [ ] Check Google AI: https://makersuite.google.com/

## Common Issues & Solutions

### Issue: "Authentication not working"
**Solution:** Verify Email/Password and Google providers are enabled in Firebase Console → Authentication → Sign-in method

### Issue: "Chat not responding"
**Solution:**
1. Check API keys in Firebase Functions config: `firebase functions:config:get`
2. Verify all three APIs are configured correctly
3. Check Cloud Functions logs: `firebase functions:log`

### Issue: "Rate limit errors"
**Solution:** Wait 1 hour for rate limit to reset, or adjust limit in functions/src/index.ts (line 34)

### Issue: "Cannot access dashboard"
**Solution:** Check browser console for errors, verify authentication state, clear cookies and try again

## Firebase Console Links

- **Project Overview:** https://console.firebase.google.com/project/upstate-ai-portal/overview
- **Authentication:** https://console.firebase.google.com/project/upstate-ai-portal/authentication/users
- **Firestore Database:** https://console.firebase.google.com/project/upstate-ai-portal/firestore
- **Cloud Functions:** https://console.firebase.google.com/project/upstate-ai-portal/functions
- **Hosting:** https://console.firebase.google.com/project/upstate-ai-portal/hosting

## Expected Costs (First Month)

| Service | Estimated Cost |
|---------|----------------|
| Firebase Functions | $0-5 (within free tier) |
| Firestore | $0-2 (within free tier) |
| Firebase Hosting | $0 (free tier) |
| Anthropic Claude API | $30-80 |
| OpenAI GPT API | $20-50 |
| Google Gemini API | $5-15 |
| **Total** | **$55-152/month** |

## Success Metrics

After testing, you should have:
- ✅ Successfully created user account
- ✅ Chatted with at least 3 different AI models
- ✅ Verified usage tracking works
- ✅ Confirmed rate limiting is active
- ✅ Tested on multiple devices
- ✅ Verified security rules work
- ✅ Monitored initial costs

## Next Steps After Testing

1. **Share with external testers** (5-10 people)
2. **Gather feedback** on UX and features
3. **Monitor costs daily** for first week
4. **Adjust rate limits** if needed
5. **Plan migration to Azure** when ready for production

## Support

- **Firebase Issues:** Check Firebase Console logs
- **API Issues:** Check respective API provider dashboards
- **Code Issues:** Review GitHub repo at https://github.com/pssambila-maker/upstate_AI_portal
- **Questions:** Create an issue in GitHub repo
