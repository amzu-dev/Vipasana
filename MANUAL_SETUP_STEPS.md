# Manual Setup Steps for Vipasana

Quick setup guide to get Vipasana running with IAP and Supabase.

---

## Step 1: Apply Supabase Migration

The Supabase CLI had connection issues, so we'll apply the migration via the web dashboard.

### Method 1: Via Supabase Dashboard (Recommended)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/mifwgtdmeigmtxbfoqxk)
2. Click **"SQL Editor"** in the left sidebar
3. Click **"+ New Query"**
4. Open the file: `supabase/migrations/20251107164105_create_vipasana_tables.sql`
5. Copy **ALL** the SQL content (it's about 500 lines)
6. Paste into the SQL Editor
7. Click **"Run"** button (or press Cmd+Enter)
8. You should see: "Success. No rows returned"

### Verify Tables Created:

After running the migration, verify in **"Table Editor"**:

You should see these NEW tables (all prefixed with `vipasana_`):
- ✅ `vipasana_users` - User profiles with device ID
- ✅ `vipasana_meditation_sessions` - Session tracking
- ✅ `vipasana_user_settings` - Synced preferences
- ✅ `vipasana_subscription_history` - IAP audit trail
- ✅ `vipasana_agreement_logs` - Legal compliance
- ✅ `vipasana_api_keys` - Device authentication

All other tables (without `vipasana_` prefix) are from your other projects and will remain untouched.

---

## Step 2: Add Files to Xcode Project

The new Swift files are in the filesystem but not yet in the Xcode project.

### Add Files Manually:

1. **Open Xcode:**
   ```bash
   open Vipasana.xcodeproj
   ```

2. **Add Models:**
   - Right-click on `Vipasana/Models` folder in Xcode
   - Select **"Add Files to 'Vipasana'..."**
   - Navigate to `Vipasana/Models/`
   - Select these files (hold Cmd to select multiple):
     - `SubscriptionStatus.swift`
     - `IAPProduct.swift`
   - **UNCHECK** "Copy items if needed"
   - **CHECK** "Vipasana" target
   - Click **"Add"**

3. **Add Helper:**
   - Right-click on `Vipasana/Helpers` folder
   - Select **"Add Files to 'Vipasana'..."**
   - Navigate to `Vipasana/Helpers/`
   - Select:
     - `StoreKitManager.swift`
   - **UNCHECK** "Copy items if needed"
   - **CHECK** "Vipasana" target
   - Click **"Add"**

4. **Add Paywall View:**
   - Right-click on `Vipasana/Views` folder
   - Select **"Add Files to 'Vipasana'..."**
   - Navigate to `Vipasana/Views/Subscription/`
   - Select:
     - `PaywallView.swift`
   - **UNCHECK** "Copy items if needed"
   - **CHECK** "Vipasana" target
   - Click **"Add"**

### Verify Files Added:

In Xcode's left sidebar, you should now see:
```
Vipasana/
├── Models/
│   ├── MeditationSession.swift ✓
│   ├── BreathingSettings.swift ✓
│   ├── OnboardingData.swift ✓
│   ├── SubscriptionStatus.swift ← NEW
│   └── IAPProduct.swift ← NEW
├── Helpers/
│   ├── AudioManager.swift ✓
│   ├── GuidedMeditationManager.swift ✓
│   └── StoreKitManager.swift ← NEW
└── Views/
    ├── Subscription/ ← NEW FOLDER
    │   └── PaywallView.swift ← NEW
    └── (existing views...)
```

---

## Step 3: Build and Test

### 3.1 Build the Project

1. In Xcode, select target: **iPhone 17 Pro (Simulator)**
2. Press **Cmd+B** to build
3. Fix any build errors (there shouldn't be any)

### 3.2 Run on Simulator

1. Press **Cmd+R** to run
2. The app should launch in the simulator

### 3.3 Test Paywall (Quick Test)

To quickly see the paywall:

1. **Option A: Add Test Button to HomeView**
   - Open `HomeView.swift`
   - Add this button somewhere in the view:
   ```swift
   Button("Test Paywall") {
       showPaywall = true
   }
   .sheet(isPresented: $showPaywall) {
       PaywallView()
   }
   ```
   - Add state: `@State private var showPaywall = false`

2. **Option B: Trigger Paywall Naturally**
   - Once we add feature gating, selecting 30/45/60 min will show paywall
   - For now, use Option A for quick testing

---

## Step 4: What to Test

### Paywall Visual Check:

When paywall appears, verify:
- ✅ Beautiful gradient background (green theme)
- ✅ "Unlock Premium" title
- ✅ 5 feature rows with icons
- ✅ Two subscription cards (Monthly $4.99, Yearly $39.99)
- ✅ "BEST VALUE" badge on yearly
- ✅ "Start 7-Day Free Trial" button
- ✅ "Restore Purchases" button
- ✅ X button to close
- ✅ Terms/Privacy links at bottom

### StoreKit Manager Check:

In Xcode console, you should see:
```
✅ Loaded 0 products from App Store
📊 Subscription status updated: Free
```

(0 products is expected - we haven't set up App Store Connect yet)

---

## Step 5: Next Steps

After testing the basic UI:

### Immediate:
1. ✅ Verify Supabase tables created
2. ✅ Verify app builds and runs
3. ✅ Verify paywall UI looks good

### Short-term:
1. **Feature Gating** - Lock premium features behind subscription
2. **App Store Connect** - Set up actual IAP products
3. **StoreKit Config File** - For local testing without App Store
4. **Supabase Integration** - Device auth and cloud sync

### Medium-term:
1. **Onboarding Flow** - Welcome + Health Disclaimer
2. **Legal Documents** - Privacy Policy, Terms, Health Safety
3. **Subscription Management** - Let users manage their subscription
4. **TestFlight Beta** - Distribute to testers

---

## Troubleshooting

### Build Errors:

**"Cannot find 'StoreKitManager' in scope"**
- Make sure you added `StoreKitManager.swift` to the Xcode project
- Check that "Vipasana" target is selected when adding files

**"No such module 'StoreKit'"**
- StoreKit should be available by default
- Try: Product → Clean Build Folder, then build again

**"Cannot find 'PaywallView' in scope"**
- Make sure you added `PaywallView.swift` to the project
- Make sure it's in the correct target

### Simulator Issues:

**Simulator not showing app:**
- Check console for crashes
- Try: Hardware → Erase All Content and Settings
- Rebuild and run

### Paywall Not Showing:

**Products show $0.00:**
- Expected until App Store Connect is configured
- Will show real prices after setting up subscriptions

**"0 products loaded":**
- Normal without App Store Connect setup
- Use StoreKit Configuration file for local testing

---

## Database Migration SQL (Backup)

If you have trouble with the migration file, here's a simplified version you can run:

```sql
-- Just the essential tables for testing

CREATE TABLE IF NOT EXISTS vipasana_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT UNIQUE NOT NULL,
    display_name TEXT,
    subscription_status TEXT DEFAULT 'free',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vipasana_meditation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vipasana_users(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    duration_seconds INTEGER NOT NULL,
    session_type TEXT NOT NULL,
    completed BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX ON vipasana_meditation_sessions(user_id);
CREATE INDEX ON vipasana_meditation_sessions(start_time DESC);
```

This creates the minimum needed for testing. Run the full migration later for production.

---

## Summary Checklist

- [ ] Supabase migration applied (6 tables created)
- [ ] All 4 Swift files added to Xcode project
- [ ] Project builds successfully (Cmd+B)
- [ ] App runs on simulator (Cmd+R)
- [ ] Paywall displays correctly
- [ ] Ready for next steps (feature gating, App Store Connect)

---

**Need Help?**
- Check `APP_STORE_CONNECT_SETUP.md` for IAP setup
- Check `PRODUCTIZATION_PLAN.md` for overall roadmap
- Migration SQL: `supabase/migrations/20251107164105_create_vipasana_tables.sql`
