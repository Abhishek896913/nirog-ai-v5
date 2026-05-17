# NirogAI Production Readiness Checklist

**Status:** v5 — Partial (Auth + Core Features Built, Missing Database Schema + Fitness Module)  
**Last Updated:** 2026-05-17  
**Estimate to Production:** 1-2 weeks (depends on team size)

---

## 📋 File Inventory & Status

### Present Files (13 HTML/JS)
| File | Lines | Status | Purpose |
|------|-------|--------|---------|
| auth.html | 653 | ✅ Complete | Patient + Doctor auth UI + inline JS |
| dashboard.html | 1009 | ✅ Complete | Patient dashboard with vitals cards |
| doctor-dashboard.html | 537 | ✅ Complete | Doctor portal, patient access, Rx writer |
| doctor-auth.js | 391 | ✅ Complete | Doctor registration/login logic |
| dr-aanya.html | 422 | ✅ Complete | AI chat (Anthropic API integration) |
| hospitals.html | 532 | ✅ Complete | Hospital finder + free booking UI |
| vitals-cards.html | 484 | ✅ Complete | NadiBox health cards + sharing |
| video-consult.html | 376 | ✅ Complete | WebRTC video calls |
| reset-password.html | 147 | ✅ Complete | Password reset flow |
| admin-dashboard.html | 443 | ✅ Complete | Admin verification + stats |
| index.html | 654 | ✅ Complete | Landing page |
| vercel.json | 14 | ✅ Correct | Route rewrites |
| README.md | 11 | ⚠️ Minimal | Just placeholder |

### Missing Critical Files
| File | Impact | Priority |
|------|--------|----------|
| supabase-schema.sql | BLOCKING — App can't run without DB schema | 🔴 P0 |
| fitness.html | 4-tab fitness UI missing | 🔴 P0 |
| js/fitness.js | Food DB + calorie logic missing | 🔴 P0 |

### Missing Non-Critical Files
| File | Impact | Priority |
|------|--------|----------|
| js/core.js | Patient auth logic is in auth.html inline (works but not modular) | 🟡 P1 |
| CLAUDE.md | Codebase documentation | 🟡 P1 |

---

## 🔴 CRITICAL — Must Do Before Launch (P0)

### 1. Create Supabase Schema [BLOCKING]
**File to Create:** `supabase-schema.sql`  
**Why:** Without this, the entire app fails on startup (no tables, no auth, no data storage)

**What to include:**
- 13 tables: doctors, profiles, nadibox_cards, shared_cards, prescriptions, appointments, hospitals, hospital_bookings, food_logs, weight_logs, health_logs, lab_reports, patient_doctor_requests
- Row Level Security (RLS) policies for each table
- Indexes on foreign keys + common query columns
- Supabase Auth setup scripts

**Handoff Reference:** Section 6 (Supabase Schema) has table summary + RLS pattern  
**Effort:** 2-3 hours (DB design) + 1 hour (testing)

---

### 2. Build Fitness Module [BLOCKING]
**Files to Create:** 
- `fitness.html` (4-tab fitness UI)
- `js/fitness.js` (food DB + calorie logic)

**What's needed:**
- Canvas-based calorie ring chart (code snippet in handoff Section 5)
- Food database: 35+ Indian foods with calories/macros
- 4 meal tabs: Breakfast, Lunch, Dinner, Snacks
- Weight logging + trend chart
- Goal calculator (BMR-based)
- AI insights (high sugar alerts, low protein warnings)
- Dark theme (like MyFitnessPal)

**Handoff Reference:** Section 5 (Calorie Ring Canvas), Section 8 (50+ features checked)  
**Effort:** 6-8 hours UI/UX + 2 hours logic

---

### 3. Fix Anthropic API Security [BLOCKING]
**Current Issue:** `dr-aanya.html` calls Anthropic directly from browser → API key exposed

**Solution:**
Create `api/aanya.js` (Vercel serverless function):
```javascript
// api/aanya.js
export default async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method not allowed');
  
  const { messages } = req.body;
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.ANTHROPIC_API_KEY}`
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1000,
      system: 'You are Dr. Aanya...',
      messages
    })
  });
  
  const data = await response.json();
  res.status(200).json(data);
};
```

Then update `dr-aanya.html` to call `/api/aanya` instead of Anthropic directly.

**Effort:** 1-2 hours

---

### 4. Supabase Configuration [BLOCKING]
**Steps to Complete in Supabase Dashboard:**

1. **Run SQL Schema**
   - Go to SQL Editor → Paste `supabase-schema.sql` → Run
   - Verify all 13 tables created ✅

2. **Auth Settings**
   - Authentication → Settings → Email Confirm → OFF (for dev), ON (for prod)
   - SMTP configured for transactional emails

3. **Google OAuth**
   - Authentication → Providers → Google → Enable
   - Add Google OAuth app credentials
   - Redirect URL: `https://YOUR_DOMAIN.vercel.app/auth`

4. **Storage**
   - Storage → New Bucket → Name: `hospital-photos` → Public: ON
   - Verify uploads work in admin dashboard

5. **RLS Verification**
   - Go to each table → RLS → Verify policies are enabled
   - Test policies with sample queries

**Effort:** 1-2 hours (mostly UI clicks)

---

### 5. Environment Variables Setup
**Add to Vercel Project Settings:**
```
ANTHROPIC_API_KEY=sk-ant-...
SUPABASE_URL=https://snsmcmxxlsolnkeukyog.supabase.co
SUPABASE_KEY=eyJhbGci...
```

**Current State:** Hardcoded in JS files (temporarily acceptable for dev)  
**Before Prod:** Move to `.env.local` (for local dev only)

**Effort:** 30 minutes

---

## 🟡 IMPORTANT — Pre-Launch (P1)

### 6. Test All Auth Flows
**Checklist:**
- [ ] Patient signup with email ✅
- [ ] Patient login ✅
- [ ] Google OAuth login ✅
- [ ] Doctor registration + custom Doctor ID selection ✅
- [ ] Doctor login with Doctor ID ✅
- [ ] Forgot Doctor ID recovery ✅
- [ ] Password reset email ✅
- [ ] Doctor can't login as patient (error message) ✅
- [ ] RLS prevents patient A from seeing patient B's data ✅

**Test on:** Chrome, Safari (iOS), Edge  
**Effort:** 3-4 hours

---

### 7. Complete Landing Page (index.html)
**Current State:** Exists but likely minimal  
**Needed:**
- Hero section with NirogAI value prop
- 3-4 feature highlights (NadiBox, AI Dr. Aanya, Free Booking, Fitness)
- CTA buttons: "Patient Login" + "Doctor Signup"
- Footer with links, contact, legal

**Reference:** Section 1 (Vision & Goal)  
**Effort:** 2-3 hours design + content

---

### 8. Reset Password Flow Completion
**File:** `reset-password.html`  
**Current State:** 147 lines (likely incomplete)

**Needed:**
- Email input
- Verify email exists in DB
- Send reset link via Supabase Auth
- Token validation
- New password entry + confirmation
- Success page

**Effort:** 2 hours

---

### 9. Admin Dashboard Polish
**File:** `admin-dashboard.html`  
**What Admin Needs:**
- [ ] List of pending doctors (status = 'pending')
- [ ] Verify/Reject doctor button
- [ ] View doctor profile before approval
- [ ] Platform statistics (total users, doctors, bookings)
- [ ] Logout button

**Effort:** 3-4 hours

---

### 10. Email Template Branding
**In Supabase:**
- Go to Authentication → Email Templates
- Update "Confirm email", "Reset password", "Magic link" templates
- Add NirogAI branding, logo, Hinglish text

**Effort:** 1 hour

---

### 11. Doctor Verification Workflow
**Current Issue:** All doctors show up immediately. Need admin approval.

**Flow:**
1. Doctor registers → Status = `pending`
2. Doctor can't appear in searches until verified
3. Admin verifies → Status = `approved`
4. Doctor can now accept patient access requests

**Code:** Add `WHERE status = 'approved'` to hospital doctor search queries

**Effort:** 2 hours

---

### 12. Lab Report Upload
**Feature:** Patients upload lab PDFs/images to Supabase Storage

**What's needed:**
- File input in vitals-cards.html
- Upload to `hospital-photos` bucket (or new `lab-reports` bucket)
- Store reference in `lab_reports` table
- View/download in patient dashboard

**Effort:** 3-4 hours

---

## 🟢 NICE TO HAVE — Post-Launch (P2)

- [ ] Push notifications (when doctor shares card, new appointment)
- [ ] Expand food database (200+ items)
- [ ] Barcode scanner for food logging
- [ ] Multi-language support (Hindi, Tamil, Telugu)
- [ ] WhatsApp integration for booking confirmations
- [ ] PWA manifest for "Add to Home Screen"
- [ ] Prescription PDF export

---

## 🧪 Testing Checklist

### Unit Tests
- [ ] Doctor ID uniqueness validation
- [ ] Calorie calculator (BMI, macro splits)
- [ ] RLS policies (data isolation)

### Integration Tests
- [ ] Patient signup → Auto-creates profile
- [ ] Doctor shares card → Patient receives link
- [ ] Hospital booking → Confirmation email sent
- [ ] Prescription write → Patient sees in dashboard

### Load Tests
- [ ] 100 concurrent users on dashboard
- [ ] Hospital search with 1000+ hospitals
- [ ] Video call WebRTC stability

### Cross-Browser
- [ ] Chrome (Windows, Mac, Android)
- [ ] Safari (Mac, iOS)
- [ ] Edge (Windows)

### Network Conditions
- [ ] 4G (2 Mbps) — should load in <3s
- [ ] 3G (1 Mbps) — acceptable load time
- [ ] Offline mode (cached data, queue requests)

**Effort:** 8-10 hours total

---

## 🚀 Deployment Sequence

### Phase 1: Setup (Day 1)
1. [ ] Create Supabase project
2. [ ] Run SQL schema
3. [ ] Configure Google OAuth
4. [ ] Create Storage bucket
5. [ ] Test Supabase directly (queries, auth)

### Phase 2: Build Missing (Days 2-4)
1. [ ] Build fitness.html + js/fitness.js
2. [ ] Complete reset-password.html
3. [ ] Create api/aanya.js serverless function
4. [ ] Polish admin-dashboard.html

### Phase 3: Test (Days 5-6)
1. [ ] Test all auth flows
2. [ ] Test all features end-to-end
3. [ ] Test on mobile (4G network)
4. [ ] Load test

### Phase 4: Deploy (Day 7)
1. [ ] Initialize GitHub repo
2. [ ] Push to GitHub
3. [ ] Connect Vercel to GitHub
4. [ ] Deploy to Vercel
5. [ ] Verify all routes work
6. [ ] Smoke test in production

---

## 📦 Code Organization Recommendation

**Current (Inline JS in HTML files):**
- Pro: No build step, simple to understand
- Con: Hard to maintain, duplicated code, large HTML files

**Recommended (Modular):**
```
nirogai/
├── api/
│   └── aanya.js          # Anthropic proxy (Vercel function)
├── js/
│   ├── core.js           # Extract from auth.html
│   ├── doctor.js         # Extract from doctor-auth.js
│   └── fitness.js        # New fitness logic
├── *.html                # Keep thin HTML files
└── README.md
```

**Migration Effort:** Not urgent for MVP, but recommended before scaling

---

## 🔐 Security Checklist

- [ ] API keys NOT hardcoded in frontend
- [ ] RLS policies enabled on all tables
- [ ] HTTPS enforced (Vercel default ✅)
- [ ] Password hashing via Supabase Auth (✅ built-in)
- [ ] No PII in browser console logs
- [ ] CORS configured correctly
- [ ] Rate limiting on signup/login
- [ ] Email verification required before doctor appears in search

**Effort:** Already 80% done via Supabase RLS + Auth

---

## 📊 Estimated Timeline

| Phase | Tasks | Effort | Timeline |
|-------|-------|--------|----------|
| Critical (P0) | Fitness + Schema + API Security | 10-12 hrs | Days 1-3 |
| Important (P1) | Testing + Auth + Reset password | 12-15 hrs | Days 4-5 |
| Nice to Have (P2) | Push notifications, Multi-lang | 15-20 hrs | Post-launch |

**Total Pre-Launch:** ~22-27 hours  
**With testing:** ~35-40 hours  
**1-2 weeks for solo developer, 3-4 days for team of 2-3**

---

## 🎯 Go-Live Criteria

Before launching to users:
1. [ ] All P0 tasks completed ✅
2. [ ] All auth flows tested on mobile ✅
3. [ ] Database backup strategy documented ✅
4. [ ] 24/7 monitoring setup (Vercel alerts) ✅
5. [ ] Support email configured ✅
6. [ ] Privacy policy + T&C linked ✅
7. [ ] Monitoring/logging configured (Sentry recommended) ✅

---

*Generated: 2026-05-17 | NirogAI v5 | Production Readiness Assessment*
