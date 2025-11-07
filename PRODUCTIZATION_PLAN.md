# Vipasana App Productization Plan

**Version:** 1.0
**Date:** November 2025
**Project:** Privacy-First Meditation App with Cloud Sync & Monetization

---

## Table of Contents

1. [Phase 1: Privacy-First Data Architecture](#phase-1-privacy-first-data-architecture)
2. [Phase 2: Supabase Database Schema](#phase-2-supabase-database-schema)
3. [Phase 3: Health & Safety Agreement](#phase-3-health--safety-agreement)
4. [Phase 4: Supabase Integration](#phase-4-supabase-integration)
5. [Phase 5: Monetization Strategy](#phase-5-monetization-strategy)
6. [Phase 6: Implementation Roadmap](#phase-6-implementation-roadmap)
7. [Phase 7: Key Files to Create/Modify](#phase-7-key-files-to-createmodify)
8. [Phase 8: Privacy & Compliance Checklist](#phase-8-privacy--compliance-checklist)
9. [Cost Analysis](#cost-analysis)
10. [Next Steps](#next-steps)

---

## Phase 1: Privacy-First Data Architecture

### 1.1 Data Classification

#### Local-Only Data (Never Synced):
- Audio files (meditation guides, bells)
- App preferences (colors, breathing patterns) - stored in UserDefaults
- Temporary session state
- Cached Lottie animations

#### Syncable Data (Encrypted):
- Meditation session records (timestamps, duration, type, completion status)
- User profile (display name, preferences)
- Subscription status and history
- Health agreement acceptance records

#### Anonymous Analytics (Optional, User Consent Required):
- App usage patterns (sessions per week, average duration)
- Feature adoption (guided vs unguided, preferred durations)
- Crash reports (via Apple's crash reporting)

### 1.2 Privacy Principles

1. **Anonymous by Default**: Use UUID-based user IDs, no email required for core features
2. **Encryption at Rest**: Sensitive data encrypted in Supabase using RLS
3. **Minimal Data Collection**: Only collect what's necessary for sync and features
4. **User Control**: Easy data export (JSON) and complete deletion
5. **GDPR/CCPA Compliant**: Right to access, delete, and port data
6. **No Third-Party Tracking**: No Facebook/Google Analytics, only essential analytics
7. **Offline-First**: All core features work without internet connection

### 1.3 Data Flow

```
┌─────────────┐
│   SwiftData │  ◄── Primary storage (local)
│  (Local DB) │
└──────┬──────┘
       │
       │ Optional Sync (user enabled)
       ▼
┌─────────────┐
│  Sync Layer │  ◄── Conflict resolution, encryption
└──────┬──────┘
       │
       │ HTTPS + RLS
       ▼
┌─────────────┐
│  Supabase   │  ◄── Cloud backup (encrypted)
│  PostgreSQL │
└─────────────┘
```

---

## Phase 2: Supabase Database Schema

### 2.1 Table Prefix Convention

**Prefix:** `vipasana_`
**Reason:** Separate from other apps in shared ZenWalk database
**Example:** `vipasana_users`, `vipasana_meditation_sessions`

### 2.2 Database Tables

#### Table: `vipasana_users`

```sql
CREATE TABLE vipasana_users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    anonymous_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Privacy & Compliance
    health_agreement_accepted BOOLEAN DEFAULT FALSE,
    health_agreement_accepted_at TIMESTAMPTZ,
    health_agreement_version TEXT,
    privacy_policy_accepted BOOLEAN DEFAULT FALSE,
    privacy_policy_version TEXT,
    privacy_policy_accepted_at TIMESTAMPTZ,
    terms_accepted BOOLEAN DEFAULT FALSE,
    terms_version TEXT,
    terms_accepted_at TIMESTAMPTZ,

    -- Preferences (encrypted JSON)
    preferences JSONB,

    -- Subscription
    subscription_status TEXT CHECK (subscription_status IN ('free', 'trial', 'monthly', 'yearly', 'lifetime')) DEFAULT 'free',
    subscription_tier TEXT CHECK (subscription_tier IN ('free', 'premium')) DEFAULT 'free',
    subscription_start_date TIMESTAMPTZ,
    subscription_end_date TIMESTAMPTZ,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,

    -- Apple IAP
    original_transaction_id TEXT,
    latest_receipt TEXT
);

-- Indexes
CREATE INDEX idx_vipasana_users_anonymous_id ON vipasana_users(anonymous_id);
CREATE INDEX idx_vipasana_users_subscription_status ON vipasana_users(subscription_status);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_vipasana_users_updated_at
    BEFORE UPDATE ON vipasana_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

#### Table: `vipasana_meditation_sessions`

```sql
CREATE TABLE vipasana_meditation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,

    -- Session data
    start_time TIMESTAMPTZ NOT NULL,
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    session_type TEXT NOT NULL,
    is_guided BOOLEAN DEFAULT FALSE,
    completed BOOLEAN DEFAULT TRUE,

    -- Metadata for sync
    device_id TEXT NOT NULL,
    local_id TEXT, -- Original SwiftData ID for deduplication
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX idx_vipasana_sessions_user_id ON vipasana_meditation_sessions(user_id);
CREATE INDEX idx_vipasana_sessions_start_time ON vipasana_meditation_sessions(user_id, start_time DESC);
CREATE INDEX idx_vipasana_sessions_device_local ON vipasana_meditation_sessions(user_id, device_id, local_id);

-- Prevent duplicate sessions from same device
CREATE UNIQUE INDEX idx_vipasana_sessions_unique ON vipasana_meditation_sessions(user_id, device_id, local_id)
    WHERE local_id IS NOT NULL;

-- Updated at trigger
CREATE TRIGGER update_vipasana_sessions_updated_at
    BEFORE UPDATE ON vipasana_meditation_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

#### Table: `vipasana_user_settings`

```sql
CREATE TABLE vipasana_user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,

    -- Breathing settings
    breathing_inhale_duration NUMERIC(4,1) DEFAULT 6.0 CHECK (breathing_inhale_duration BETWEEN 2.0 AND 10.0),
    breathing_exhale_duration NUMERIC(4,1) DEFAULT 6.0 CHECK (breathing_exhale_duration BETWEEN 2.0 AND 10.0),
    interval_bells_enabled BOOLEAN DEFAULT TRUE,

    -- Appearance settings
    background_color TEXT,
    circle_color TEXT,

    -- Sync metadata
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT NOT NULL,

    CONSTRAINT unique_user_settings UNIQUE(user_id)
);

-- Index
CREATE INDEX idx_vipasana_settings_user ON vipasana_user_settings(user_id);

-- Updated at trigger
CREATE TRIGGER update_vipasana_settings_updated_at
    BEFORE UPDATE ON vipasana_user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

#### Table: `vipasana_subscription_history`

```sql
CREATE TABLE vipasana_subscription_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,

    -- Event details
    event_type TEXT NOT NULL CHECK (event_type IN (
        'trial_started',
        'trial_ended',
        'trial_converted',
        'subscribed',
        'renewed',
        'cancelled',
        'expired',
        'refunded',
        'billing_issue'
    )),
    subscription_tier TEXT CHECK (subscription_tier IN ('monthly', 'yearly', 'lifetime')),

    -- Apple IAP details
    transaction_id TEXT,
    original_transaction_id TEXT,
    product_id TEXT,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB
);

-- Indexes
CREATE INDEX idx_vipasana_subscription_history_user ON vipasana_subscription_history(user_id, created_at DESC);
CREATE INDEX idx_vipasana_subscription_history_event ON vipasana_subscription_history(event_type, created_at DESC);
```

#### Table: `vipasana_agreement_logs`

```sql
CREATE TABLE vipasana_agreement_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,

    -- Agreement details
    agreement_type TEXT NOT NULL CHECK (agreement_type IN ('health_safety', 'privacy_policy', 'terms_of_service')),
    agreement_version TEXT NOT NULL,
    accepted BOOLEAN NOT NULL,
    accepted_at TIMESTAMPTZ DEFAULT NOW(),

    -- Compliance metadata
    ip_address INET,
    user_agent TEXT,
    device_info JSONB
);

-- Indexes
CREATE INDEX idx_vipasana_agreement_logs_user ON vipasana_agreement_logs(user_id, agreement_type, accepted_at DESC);
CREATE INDEX idx_vipasana_agreement_logs_type ON vipasana_agreement_logs(agreement_type, agreement_version);
```

### 2.3 Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE vipasana_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE vipasana_meditation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE vipasana_user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE vipasana_subscription_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE vipasana_agreement_logs ENABLE ROW LEVEL SECURITY;

-- vipasana_users policies
CREATE POLICY "Users can view own profile"
    ON vipasana_users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON vipasana_users FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON vipasana_users FOR UPDATE
    USING (auth.uid() = id);

-- vipasana_meditation_sessions policies
CREATE POLICY "Users can view own sessions"
    ON vipasana_meditation_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
    ON vipasana_meditation_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions"
    ON vipasana_meditation_sessions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions"
    ON vipasana_meditation_sessions FOR DELETE
    USING (auth.uid() = user_id);

-- vipasana_user_settings policies
CREATE POLICY "Users can view own settings"
    ON vipasana_user_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings"
    ON vipasana_user_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings"
    ON vipasana_user_settings FOR UPDATE
    USING (auth.uid() = user_id);

-- vipasana_subscription_history policies (read-only for users)
CREATE POLICY "Users can view own subscription history"
    ON vipasana_subscription_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "System can insert subscription history"
    ON vipasana_subscription_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- vipasana_agreement_logs policies
CREATE POLICY "Users can view own agreements"
    ON vipasana_agreement_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own agreements"
    ON vipasana_agreement_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);
```

### 2.4 Database Functions

```sql
-- Function to get user statistics
CREATE OR REPLACE FUNCTION vipasana_get_user_stats(p_user_id UUID)
RETURNS TABLE (
    total_sessions BIGINT,
    total_minutes BIGINT,
    completed_sessions BIGINT,
    avg_duration_minutes NUMERIC,
    first_session_date TIMESTAMPTZ,
    last_session_date TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT as total_sessions,
        SUM(duration_seconds / 60)::BIGINT as total_minutes,
        COUNT(*) FILTER (WHERE completed = true)::BIGINT as completed_sessions,
        AVG(duration_seconds / 60.0)::NUMERIC(10,2) as avg_duration_minutes,
        MIN(start_time) as first_session_date,
        MAX(start_time) as last_session_date
    FROM vipasana_meditation_sessions
    WHERE user_id = p_user_id;
END;
$$;

-- Function to calculate streak (simplified version)
CREATE OR REPLACE FUNCTION vipasana_calculate_streak(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_streak INTEGER := 0;
    v_current_date DATE := CURRENT_DATE;
    v_has_session BOOLEAN;
BEGIN
    -- Simple streak calculation: consecutive days with at least one completed session
    LOOP
        SELECT EXISTS(
            SELECT 1
            FROM vipasana_meditation_sessions
            WHERE user_id = p_user_id
              AND DATE(start_time) = v_current_date
              AND completed = true
        ) INTO v_has_session;

        EXIT WHEN NOT v_has_session;

        v_streak := v_streak + 1;
        v_current_date := v_current_date - INTERVAL '1 day';
    END LOOP;

    RETURN v_streak;
END;
$$;

-- Function to check subscription status
CREATE OR REPLACE FUNCTION vipasana_check_subscription_active(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_status TEXT;
    v_end_date TIMESTAMPTZ;
BEGIN
    SELECT subscription_status, subscription_end_date
    INTO v_status, v_end_date
    FROM vipasana_users
    WHERE id = p_user_id;

    IF v_status IN ('trial', 'monthly', 'yearly', 'lifetime') THEN
        IF v_status = 'lifetime' OR v_end_date IS NULL OR v_end_date > NOW() THEN
            RETURN TRUE;
        END IF;
    END IF;

    RETURN FALSE;
END;
$$;
```

---

## Phase 3: Health & Safety Agreement

### 3.1 Required Legal Documents

Three documents must be created and versioned:

1. **Health & Safety Disclaimer** (v1.0)
2. **Privacy Policy** (v1.0)
3. **Terms of Service** (v1.0)

All documents will be stored in `/Resources/Legal/` directory.

### 3.2 Health & Safety Disclaimer Content

Key points to include:

- **Medical Disclaimer**: Not a medical device or treatment
- **Consult Healthcare Provider**: Especially for mental health conditions
- **Stop If Uncomfortable**: Users should stop if experiencing distress
- **Age Restriction**: 13+ years old (or parental consent)
- **Physical Safety**: Practice in safe environment
- **No Guarantees**: Results vary per individual
- **Emergency Notice**: App not for crisis intervention

### 3.3 Privacy Policy Content

Key points to include:

- **Data Collection**: What we collect (sessions, preferences)
- **Data Usage**: How we use it (sync, features, improvement)
- **Data Storage**: Where it's stored (Supabase, encrypted)
- **Data Sharing**: Who we share with (none, except Apple for IAP)
- **User Rights**: Access, export, delete data
- **Cookies**: None used
- **Children's Privacy**: COPPA compliance
- **Changes**: How we notify of policy updates
- **Contact**: How to reach us

### 3.4 Terms of Service Content

Key points to include:

- **Acceptable Use**: How app should be used
- **Account Terms**: Anonymous account details
- **Subscription Terms**: Billing, renewals, cancellations
- **Refund Policy**: Apple's refund process
- **Intellectual Property**: App content ownership
- **Liability Limitations**: What we're not responsible for
- **Dispute Resolution**: Arbitration clause
- **Termination**: Account closure terms

### 3.5 Onboarding Flow

```
App Launch
    ↓
Check: First Launch?
    ↓ NO → Main App
    ↓ YES
    ↓
Welcome Screen
    ├─ App Introduction
    ├─ Key Features
    └─ Beautiful UI Preview
    ↓
Health & Safety Agreement
    ├─ Full Scrollable Text
    ├─ "I Understand" Checkbox
    └─ Accept Button (disabled until scroll + check)
    ↓
Privacy Policy
    ├─ Full Scrollable Text
    ├─ "I Accept" Checkbox
    └─ Accept Button
    ↓
Terms of Service
    ├─ Full Scrollable Text
    ├─ "I Agree" Checkbox
    └─ Accept Button
    ↓
Optional: Create Account
    ├─ "Sign in with Apple" (anonymous)
    ├─ Benefits explanation (sync)
    └─ "Skip for Now" option
    ↓
Main App (Home View)
```

### 3.6 Agreement Tracking

Track user acceptance in:
- Local: SwiftData `UserAgreement` model
- Remote: `vipasana_agreement_logs` table

Include:
- Agreement type and version
- Timestamp of acceptance
- Device information
- IP address (for compliance only)

---

## Phase 4: Supabase Integration

### 4.1 Dependencies

Add Supabase Swift SDK via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

### 4.2 Supabase Client Configuration

Create `SupabaseClient.swift` as singleton:

```swift
import Supabase

@MainActor
class SupabaseClient: ObservableObject {
    static let shared = SupabaseClient()

    private(set) var client: SupabaseClient!
    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private init() {
        // Load from Supabase.plist (not in git)
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("Supabase configuration missing")
        }

        client = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: anonKey
        )
    }
}
```

### 4.3 Authentication Strategy

**Anonymous Authentication (Recommended):**
- No email required for core features
- Automatic account creation on first sync
- Can upgrade to Apple Sign In later

**Apple Sign In (Premium Option):**
- For users who want email-based recovery
- Links to anonymous account
- Better user experience for multi-device

### 4.4 Sync Strategy

**Offline-First Architecture:**
1. All writes go to SwiftData first (instant)
2. Background sync when online
3. Conflict resolution: Last-write-wins with timestamp
4. Deduplication using device_id + local_id

**Sync Triggers:**
- On app launch (if online)
- After creating/updating session
- On settings change
- Manual refresh pull-down
- When app enters foreground

**Sync Manager Responsibilities:**
- Upload local changes
- Download remote changes
- Resolve conflicts
- Handle network errors gracefully
- Retry failed syncs

---

## Phase 5: Monetization Strategy

### 5.1 Subscription Tiers

#### Free Tier (Core Features):
- ✅ 15-minute unguided meditation
- ✅ Basic breathing circle animation
- ✅ Local session history
- ✅ 3 completion animations
- ✅ Basic statistics
- ❌ No cloud sync
- ❌ No guided meditation
- ❌ Limited durations

#### Premium Tier - Monthly ($4.99/month):
- ✅ All meditation durations (15, 30, 45, 60 min)
- ✅ Guided meditation with voiceovers
- ✅ Cloud sync across devices
- ✅ All 5 completion animations
- ✅ Advanced breathing patterns (4:6 and 6:6)
- ✅ Interval bell customization
- ✅ Detailed statistics and insights
- ✅ Data export (JSON)
- ✅ Priority support

#### Premium Tier - Yearly ($39.99/year):
- ✅ All monthly features
- ✅ Save 33% compared to monthly
- ✅ Early access to new features
- ✅ Lifetime priority support

#### Trial Period:
- 7-day free trial for both tiers
- Full access to all premium features
- Cancel anytime during trial
- Auto-renews unless cancelled 24h before

### 5.2 Product IDs

```
com.amzuit.vipasana.monthly
com.amzuit.vipasana.yearly
```

### 5.3 Feature Gating

| Feature | Free | Premium |
|---------|------|---------|
| 15min unguided | ✅ | ✅ |
| 30min unguided | ❌ | ✅ |
| 45min unguided | ❌ | ✅ |
| 60min unguided | ❌ | ✅ |
| 15min guided | ❌ | ✅ |
| Cloud sync | ❌ | ✅ |
| Breathing customization | Limited | ✅ |
| All animations | 3/5 | 5/5 |
| Data export | ❌ | ✅ |

### 5.4 Paywall Strategy

**Trigger Points:**
- After 3 free meditation sessions (soft paywall)
- When selecting guided meditation
- When selecting 30+ minute duration
- When trying to enable cloud sync
- On settings screen for premium features

**Paywall Design:**
- Benefit-focused headline
- Feature comparison table
- Social proof ("Join 10,000+ peaceful minds")
- Clear pricing with trial emphasis
- "Restore Purchases" button
- "Not now" option (for soft paywalls)

### 5.5 Trial Experience

**Trial Countdown UI:**
- Subtle badge in settings: "5 days left in trial"
- Reminder 2 days before trial ends
- One notification 1 day before trial ends
- Smooth transition to paid or cancelled

---

## Phase 6: Implementation Roadmap

### Week 1-2: Foundation & Database
- [x] Create productization plan
- [ ] Set up Supabase tables in ZenWalk project
- [ ] Configure RLS policies
- [ ] Test database functions
- [ ] Create legal documents (3 documents)
- [ ] Add legal documents to project

### Week 3-4: Onboarding & Authentication
- [ ] Create onboarding models (AgreementVersion, UserAgreement)
- [ ] Build WelcomeView
- [ ] Build HealthSafetyAgreementView
- [ ] Build PrivacyPolicyView
- [ ] Build TermsOfServiceView
- [ ] Integrate Supabase Swift SDK
- [ ] Implement SupabaseClient
- [ ] Add anonymous authentication
- [ ] Test onboarding flow

### Week 5-6: Sync Implementation
- [ ] Create SyncManager class
- [ ] Implement session sync (upload)
- [ ] Implement session sync (download)
- [ ] Implement settings sync
- [ ] Add conflict resolution
- [ ] Add sync status UI
- [ ] Test offline/online transitions
- [ ] Test multi-device sync

### Week 7-8: Monetization Setup
- [ ] Set up App Store Connect subscriptions
- [ ] Create StoreKit configuration file
- [ ] Implement StoreKitManager
- [ ] Add subscription status tracking
- [ ] Build PaywallView
- [ ] Build SubscriptionManagementView
- [ ] Implement feature gating
- [ ] Test IAP in sandbox

### Week 9-10: Premium Features & Polish
- [ ] Lock guided meditation behind paywall
- [ ] Lock 30/45/60 min durations
- [ ] Add trial countdown UI
- [ ] Implement data export (JSON)
- [ ] Add subscription management screen
- [ ] Implement account deletion
- [ ] Add privacy controls
- [ ] Test all premium features

### Week 11-12: Launch Preparation
- [ ] TestFlight beta testing
- [ ] Fix reported bugs
- [ ] App Store screenshots (all sizes)
- [ ] App Store description & keywords
- [ ] Privacy nutrition labels
- [ ] Support website setup
- [ ] Final testing on real devices
- [ ] Submit to App Store Review

---

## Phase 7: Key Files to Create/Modify

### New Directory Structure

```
Vipasana/
├── Models/
│   ├── MeditationSession.swift (existing)
│   ├── BreathingSettings.swift (existing)
│   ├── OnboardingData.swift (new)
│   ├── AgreementVersion.swift (new)
│   ├── UserAgreement.swift (new)
│   ├── SubscriptionStatus.swift (new)
│   └── IAPProduct.swift (new)
│
├── Views/
│   ├── Onboarding/ (new folder)
│   │   ├── WelcomeView.swift
│   │   ├── HealthSafetyAgreementView.swift
│   │   ├── PrivacyPolicyView.swift
│   │   ├── TermsOfServiceView.swift
│   │   └── OnboardingContainerView.swift
│   │
│   ├── Subscription/ (new folder)
│   │   ├── PaywallView.swift
│   │   ├── SubscriptionManagementView.swift
│   │   ├── FeatureLockedView.swift
│   │   └── TrialCountdownBadge.swift
│   │
│   ├── Privacy/ (new folder)
│   │   ├── DataExportView.swift
│   │   ├── DataDeletionView.swift
│   │   └── PrivacyControlsView.swift
│   │
│   ├── Settings/ (modify existing)
│   │   └── SettingsView.swift (add account section)
│   │
│   └── (existing views remain)
│
├── Helpers/
│   ├── AudioManager.swift (existing)
│   ├── GuidedMeditationManager.swift (existing)
│   ├── SupabaseClient.swift (new)
│   ├── SyncManager.swift (new)
│   ├── StoreKitManager.swift (new)
│   └── DeviceIdentifier.swift (new)
│
├── Resources/
│   ├── Legal/ (new folder)
│   │   ├── health_safety_v1.md
│   │   ├── privacy_policy_v1.md
│   │   └── terms_of_service_v1.md
│   │
│   └── (existing resources)
│
├── Configuration/
│   ├── Supabase.plist (new, in .gitignore)
│   └── Info.plist (modify for Supabase keys)
│
└── Supporting Files/
    ├── VipasanaApp.swift (modify for onboarding check)
    └── StoreKit.storekit (new, for testing)
```

### Files to Create

1. **Models (7 new files)**
   - OnboardingData.swift
   - AgreementVersion.swift
   - UserAgreement.swift
   - SubscriptionStatus.swift
   - IAPProduct.swift
   - SyncStatus.swift
   - UserProfile.swift

2. **Views (13 new files)**
   - Onboarding: 5 files
   - Subscription: 4 files
   - Privacy: 3 files
   - Shared components: 1 file

3. **Helpers (4 new files)**
   - SupabaseClient.swift
   - SyncManager.swift
   - StoreKitManager.swift
   - DeviceIdentifier.swift

4. **Legal Documents (3 files)**
   - health_safety_v1.md
   - privacy_policy_v1.md
   - terms_of_service_v1.md

5. **Configuration (2 files)**
   - Supabase.plist
   - StoreKit.storekit

**Total: 29 new files**

---

## Phase 8: Privacy & Compliance Checklist

### App Store Privacy Nutrition Labels

**Data Linked to User:**
- [ ] Email Address (optional, only with Apple Sign In)
- [ ] User ID (anonymous UUID)
- [ ] Health & Fitness: Meditation sessions (duration, timestamp)

**Data Not Linked to User:**
- [ ] Crash Data (via Apple)
- [ ] Performance Data (via Apple)

**Data Not Collected:**
- ✅ No location data
- ✅ No contacts
- ✅ No photos
- ✅ No camera
- ✅ No microphone
- ✅ No browsing history
- ✅ No search history
- ✅ No device ID (except for sync)

### GDPR Compliance

- [ ] Privacy policy displayed before data collection
- [ ] Explicit consent for tracking (none required)
- [ ] Right to access data (export feature)
- [ ] Right to deletion (account deletion)
- [ ] Right to portability (JSON export)
- [ ] Data retention policy (2 years inactive = delete)
- [ ] Data processing agreement (Supabase DPA)
- [ ] Cookie consent (N/A - no cookies)
- [ ] Breach notification procedures

### CCPA Compliance

- [ ] Privacy policy includes CCPA disclosures
- [ ] "Do Not Sell My Info" (N/A - we don't sell)
- [ ] Right to know what data is collected
- [ ] Right to delete personal information
- [ ] Right to opt-out of data selling (N/A)
- [ ] Non-discrimination for exercising rights

### COPPA Compliance (Children's Privacy)

- [ ] Age gate: 13+ years old requirement
- [ ] Parental consent mechanism (if allowing under 13)
- [ ] No targeted advertising to children
- [ ] Minimal data collection
- [ ] Clear privacy policy

### Apple App Store Guidelines

- [ ] 1.4.4: Medical disclaimer prominent
- [ ] 2.1: Native SwiftUI app
- [ ] 3.1.2: Subscriptions properly implemented
- [ ] 3.1.3: "Restore Purchases" available
- [ ] 5.1.1: Privacy policy accessible
- [ ] 5.1.2: Data usage disclosed
- [ ] Family Sharing enabled for subscriptions

### Health & Safety Compliance

- [ ] Clear disclaimer: Not medical advice
- [ ] Warning: Consult doctor for conditions
- [ ] Emergency notice: Not for crisis
- [ ] Physical safety guidance
- [ ] Age restriction enforcement
- [ ] No medical claims or cures

---

## Cost Analysis

### One-Time Costs

| Item | Cost | Notes |
|------|------|-------|
| Apple Developer Account | $99/year | Required for App Store |
| App Icon Design | $100-500 | One-time professional design |
| Legal Review (Optional) | $500-2000 | Attorney review of terms |
| **Total One-Time** | **$699-2599** | |

### Monthly Costs

| Item | Cost | Notes |
|------|------|-------|
| Supabase | $0-25 | Free tier → Pro at 1000+ users |
| Domain (Optional) | $1-2 | For support website |
| Email Service | $0 | Use free tier (Supabase) |
| **Total Monthly** | **$0-27** | Scales with users |

### Revenue Projections

#### Conservative Scenario (Year 1)
- Downloads: 1,000
- Free users: 800 (80%)
- Trial starts: 200 (20%)
- Trial conversions: 40 (20% of trials)
- Yearly subscribers: 30 (75% yearly)
- Monthly subscribers: 10 (25% monthly)

**Annual Revenue:**
- Yearly: 30 × $39.99 = $1,199.70
- Monthly: 10 × $4.99 × 12 = $598.80
- **Total: $1,798.50**

**After Apple's 30% cut: $1,258.95**

#### Moderate Scenario (Year 2)
- Downloads: 5,000
- Paid subscribers: 250
- **Annual Revenue: $8,747.50**
- **After Apple cut: $6,123.25**

#### Optimistic Scenario (Year 3)
- Downloads: 10,000
- Paid subscribers: 600
- **Annual Revenue: $20,994**
- **After Apple cut: $14,695.80**

### Break-Even Analysis

**Monthly Break-Even (assuming $25 Supabase):**
- Need: 6 monthly subscribers OR 2 yearly subscribers
- Or mix: 3 monthly + 1 yearly

**With Apple cut at 30%:**
- $4.99 monthly = $3.49 to you
- $39.99 yearly = $27.99 to you

**To cover $99 Apple fee + $300 Supabase yearly:**
- Need 115 monthly subscriber-months per year
- Or 15 yearly subscribers
- **Realistic target: 20-30 paying customers for break-even**

---

## Next Steps

### Immediate Actions (This Week)

1. **Set up Supabase Database**
   - Connect to ZenWalk project via Supabase CLI
   - Run migration scripts to create tables
   - Configure RLS policies
   - Test database functions

2. **Create Legal Documents**
   - Draft Health & Safety Disclaimer
   - Draft Privacy Policy
   - Draft Terms of Service
   - Save as versioned markdown files

3. **Start Onboarding Implementation**
   - Create data models for agreements
   - Build welcome screen
   - Build agreement acceptance views

### Phase Priority

**Phase 1-2 (Critical Foundation):**
- Database setup with Supabase
- Legal compliance documents
- Onboarding flow

**Phase 3-4 (Core Functionality):**
- Authentication integration
- Sync manager implementation
- Testing sync across devices

**Phase 5 (Revenue Generation):**
- IAP implementation
- Paywall design
- Feature gating

**Phase 6 (Launch Ready):**
- Polish and testing
- App Store submission
- Marketing preparation

---

## Success Metrics

### KPIs to Track

**User Engagement:**
- Daily Active Users (DAU)
- Weekly Active Users (WAU)
- Average sessions per user per week
- Average session duration
- Retention: Day 1, Day 7, Day 30

**Monetization:**
- Trial start rate
- Trial conversion rate
- Monthly Recurring Revenue (MRR)
- Average Revenue Per User (ARPU)
- Churn rate
- Lifetime Value (LTV)

**Product Health:**
- App Store rating (target: 4.5+)
- Crash-free rate (target: 99.9%)
- Sync success rate (target: 99%)
- Feature adoption rates

---

## Risk Mitigation

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Sync conflicts | High | Last-write-wins + device ID tracking |
| Data loss | Critical | Offline-first + regular backups |
| IAP receipt validation | High | Server-side validation via Supabase |
| API rate limits | Medium | Implement exponential backoff |
| Supabase downtime | Medium | Graceful degradation, local cache |

### Business Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Low conversion rate | High | Strong trial experience, clear value |
| High churn | High | Engagement features, progress tracking |
| App Store rejection | Critical | Follow guidelines, thorough testing |
| Competition | Medium | Focus on privacy, simplicity, beauty |
| Negative reviews | Medium | Excellent support, quality app |

### Legal Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Privacy violation | Critical | Strict data minimization, transparency |
| Health claim issues | High | Clear disclaimers, no medical claims |
| Subscription disputes | Medium | Clear terms, easy cancellation |
| Copyright issues | Medium | Use only owned/licensed content |

---

## Conclusion

This productization plan transforms Vipasana from a personal meditation app into a privacy-first, sustainable business. Key differentiators:

1. **Privacy-First**: Anonymous by default, minimal data collection
2. **Offline-First**: Core features work without internet
3. **Simple Monetization**: Clear value proposition, fair pricing
4. **User-Centric**: Focused on meditation experience, not growth hacks
5. **Quality Over Quantity**: Polish and reliability over feature bloat

**Timeline:** 12 weeks to launch
**Investment:** ~$700-2600 upfront, $0-25/month ongoing
**Break-even:** 20-30 paying customers
**Target:** 600+ paying customers by Year 3

---

*Let's build something mindful together.* 🧘‍♂️
