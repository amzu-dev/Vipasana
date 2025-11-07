# App Store Connect Setup Guide for Vipasana

This guide walks you through setting up In-App Purchases (IAP) and subscriptions in App Store Connect.

---

## Prerequisites

- Apple Developer Account ($99/year)
- Vipasana app created in App Store Connect
- Tax and banking information completed in App Store Connect

---

## Step 1: Create App in App Store Connect

### 1.1 Log in to App Store Connect
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account

### 1.2 Create New App
1. Click "My Apps"
2. Click the "+" button and select "New App"
3. Fill in:
   - **Platform:** iOS
   - **Name:** Vipasana
   - **Primary Language:** English (US)
   - **Bundle ID:** com.amzuit.Vipasana (must match Xcode)
   - **SKU:** vipasana-app (unique identifier)
   - **User Access:** Full Access

---

## Step 2: Set Up Subscriptions

### 2.1 Create Subscription Group

1. In your app, go to **"Features" → "Subscriptions"**
2. Click **"+"** to create a new subscription group
3. Fill in:
   - **Reference Name:** Vipasana Premium
   - **App Store Localized Name (English):** Premium Meditation

### 2.2 Create Monthly Subscription

1. Inside the subscription group, click **"+"** to add a subscription
2. Fill in:
   - **Product ID:** `com.amzuit.vipasana.monthly`
   - **Reference Name:** Monthly Premium Subscription

3. **Subscription Duration:**
   - Select: **1 Month**

4. **Subscription Prices:**
   - Click **"Add Subscription Price"**
   - **Price:** $4.99 USD
   - **Availability:** All territories (or select specific)
   - Click **"Next"** and **"Add"**

5. **Localization (English - US):**
   - **Subscription Display Name:** Monthly Premium
   - **Description:** Access all premium meditation features including guided sessions, all durations, cloud sync, and detailed statistics.

6. **Subscription Availability:**
   - Available in all territories: ✅

7. **Free Trial:**
   - Click **"Set Up Offer"**
   - **Offer Type:** Introductory Offer
   - **Offer Duration:** 7 Days
   - **Offer Price:** Free
   - **Number of Periods:** 1
   - **After Intro:** Standard price applies
   - Click **"Save"**

8. **Review Information:**
   - Upload a **screenshot** showing what users get with premium (1242 x 2208 pixels)
   - Review notes: "Premium subscription gives access to all meditation durations, guided sessions, and cloud sync"

9. Click **"Save"** at top right

### 2.3 Create Yearly Subscription

1. In the same subscription group, click **"+"** again
2. Fill in:
   - **Product ID:** `com.amzuit.vipasana.yearly`
   - **Reference Name:** Yearly Premium Subscription

3. **Subscription Duration:**
   - Select: **1 Year**

4. **Subscription Prices:**
   - Click **"Add Subscription Price"**
   - **Price:** $39.99 USD (33% savings vs monthly)
   - **Availability:** All territories
   - Click **"Next"** and **"Add"**

5. **Localization (English - US):**
   - **Subscription Display Name:** Yearly Premium
   - **Description:** Get all premium meditation features at the best value - save 33% compared to monthly. Includes guided sessions, all durations, cloud sync, and detailed statistics.

6. **Subscription Availability:**
   - Available in all territories: ✅

7. **Free Trial:**
   - Click **"Set Up Offer"**
   - **Offer Type:** Introductory Offer
   - **Offer Duration:** 7 Days
   - **Offer Price:** Free
   - **Number of Periods:** 1
   - **After Intro:** Standard price applies
   - Click **"Save"**

8. **Review Information:**
   - Upload the same screenshot as monthly
   - Review notes: "Yearly premium subscription with 33% savings"

9. Click **"Save"**

---

## Step 3: Configure Subscription Group Settings

### 3.1 Subscription Group Settings

1. Go back to your subscription group
2. Click **"View All Sections"** or scroll down

3. **Subscription Group Display Name:**
   - English (US): Premium Meditation

4. **Family Sharing:**
   - Enable: ✅ Yes (allows sharing with family members)

---

## Step 4: App Review Information

### 4.1 Subscription Review Information

For EACH subscription (monthly and yearly):

1. **Review Information** section:
   - **Screenshot:** Upload app screenshot showing premium features
     - Use a screenshot of the paywall or premium features in action
     - Size: 1242 x 2208 pixels (iPhone 6.7" display)

   - **Review Notes:**
     ```
     To test the subscription:
     1. Launch the app
     2. Tap "Start Meditating"
     3. Select a premium duration (30, 45, or 60 min) or guided meditation
     4. The paywall will appear
     5. You can test the purchase flow with the Sandbox tester account

     Sandbox Tester: (we'll create this next)
     ```

---

## Step 5: Create Sandbox Tester Account

### 5.1 Create Test Account

1. In App Store Connect, go to **"Users and Access"**
2. Click **"Sandbox"** tab at the top
3. Click **"+"** to add a tester
4. Fill in:
   - **First Name:** Test
   - **Last Name:** User
   - **Email:** Create a NEW email (can be fake: testuser@example.com)
     - ⚠️ **Important:** Must be an email NOT associated with any Apple ID
   - **Password:** Create a strong password (save this!)
   - **Confirm Password:** Same as above
   - **Secret Question:** Choose one
   - **Secret Answer:** Your answer (save this!)
   - **Date of Birth:** Set to 18+ years old
   - **App Store Territory:** United States

5. Click **"Invite"**

### 5.2 Using Sandbox Tester

To test IAP in the simulator or TestFlight:

1. On your device/simulator, go to **Settings → App Store**
2. Scroll down to **"Sandbox Account"**
3. Sign in with the sandbox tester email and password
4. Launch Vipasana and test purchasing

⚠️ **Note:** Sandbox testers are NOT charged real money. Subscriptions renew every 5 minutes for testing.

---

## Step 6: StoreKit Configuration File (For Local Testing)

### 6.1 Create StoreKit Configuration

1. In Xcode, go to **File → New → File**
2. Search for **"StoreKit Configuration File"**
3. Name it **"Vipasana.storekit"**
4. Save in project root

### 6.2 Add Products to StoreKit File

1. Open `Vipasana.storekit`
2. Click **"+"** at bottom left
3. Select **"Add Auto-Renewable Subscription"**

#### Monthly Subscription:
- **Product ID:** com.amzuit.vipasana.monthly
- **Reference Name:** Monthly Premium
- **Price:** $4.99
- **Subscription Duration:** 1 Month
- **Introductory Offer:** 7 Days Free
- **Family Shareable:** Yes

#### Yearly Subscription:
- **Product ID:** com.amzuit.vipasana.yearly
- **Reference Name:** Yearly Premium
- **Price:** $39.99
- **Subscription Duration:** 1 Year
- **Introductory Offer:** 7 Days Free
- **Family Shareable:** Yes

### 6.3 Enable StoreKit Testing in Scheme

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **"Run"** on the left
3. Go to **"Options"** tab
4. Under **"StoreKit Configuration"**, select **"Vipasana.storekit"**
5. Click **"Close"**

Now you can test IAP locally without connecting to App Store Connect!

---

## Step 7: App Privacy & Data Usage

### 7.1 Privacy Policy URL

1. In App Store Connect, go to your app
2. Go to **"App Information"**
3. Add **Privacy Policy URL:**
   - You'll need to host this on a website
   - Example: `https://yourdomain.com/vipasana/privacy`

### 7.2 Privacy Nutrition Labels

1. Go to **"App Privacy"** section
2. Click **"Get Started"**

**Data Collection:**
- **Health & Fitness:**
  - ✅ We collect this data
  - **Data Type:** Health & Fitness (meditation times)
  - **Linked to User:** Yes
  - **Used for:** App Functionality, Analytics
  - **Tracking:** No

- **Identifiers:**
  - ✅ We collect this data
  - **Data Type:** Device ID
  - **Linked to User:** Yes
  - **Used for:** App Functionality (sync)
  - **Tracking:** No

**Data NOT Collected:**
- Location, Contacts, Photos, etc.

---

## Step 8: App Review Preparation

### 8.1 Screenshot Requirements

You need screenshots for:
- **6.7" Display (iPhone 14 Pro Max):** 1290 x 2796
- **6.5" Display (iPhone 11 Pro Max):** 1242 x 2688
- **5.5" Display (iPhone 8 Plus):** 1242 x 2208

**Suggested Screenshots:**
1. Home screen with duration options
2. Active meditation session
3. History/Statistics screen
4. Settings screen
5. Completion celebration

### 8.2 App Description

```
Vipasana - Mindful Meditation

Find peace and clarity through guided meditation. Vipasana offers a beautifully simple meditation experience designed to help you build a consistent practice.

FEATURES:
• Multiple session durations (15, 30, 45, 60 minutes)
• Guided meditation with professional voiceovers
• Breathing circle visualization
• Progress tracking and statistics
• Meditation streak counter
• Cloud sync across devices
• Customizable breathing patterns
• Interval bell sounds
• Beautiful completion animations

PREMIUM BENEFITS:
• Access all meditation durations
• Full guided meditation library
• Cloud backup and sync
• Detailed insights and analytics
• Priority support

FREE TRIAL:
Try Premium free for 7 days. Cancel anytime.

PRIVACY FIRST:
Your meditation data is private and secure. We collect minimal information and never share your data.

Terms: [Your URL]
Privacy: [Your URL]
```

### 8.3 Keywords

```
meditation, mindfulness, zen, peace, calm, relax, breathe, vipassana, insight, mindful, wellness, mental health, stress relief, anxiety, focus
```

### 8.4 Age Rating

- **Age Rating:** 4+ (No restricted content)
- **Health Disclaimer:** Include in app description

---

## Step 9: Submit for Review

### 9.1 Version Information

1. **Version:** 1.0
2. **Copyright:** 2025 Amzu IT
3. **Category:** Primary: Health & Fitness, Secondary: Lifestyle

### 9.2 Build

1. Archive your app in Xcode:
   - Select **"Any iOS Device"** as target
   - Go to **Product → Archive**
   - Wait for archive to complete
   - Click **"Distribute App"**
   - Choose **"App Store Connect"**
   - **Upload**

2. Once uploaded, go to App Store Connect
3. Select the build under **"Build"** section
4. Add **Export Compliance:** No (if not using encryption beyond HTTPS)

### 9.3 Review Notes

```
TESTING INSTRUCTIONS:

Premium Features:
To access the paywall, select any 30/45/60 minute duration or guided meditation option. The paywall will appear showing subscription options.

Sandbox Testing:
We've configured sandbox testing. Use the sandbox tester account provided.

Trial Period:
Users can try Premium free for 7 days. The trial can be cancelled anytime.

Subscription Management:
Users can manage subscriptions via Settings app → Apple ID → Subscriptions.

Contact:
support@amzu.it
```

### 9.4 Submit

1. Click **"Add for Review"**
2. Click **"Submit for Review"**
3. Wait for Apple review (typically 24-48 hours)

---

## Step 10: Post-Approval Checklist

### After Approval:

1. ✅ **Test on Real Device:**
   - Download from App Store
   - Test purchase flow
   - Verify receipt

2. ✅ **Monitor Analytics:**
   - App Store Connect → Analytics
   - Track downloads, conversions

3. ✅ **Monitor Reviews:**
   - Respond to user feedback
   - Fix reported issues quickly

4. ✅ **Revenue Tracking:**
   - App Store Connect → Sales and Trends
   - Monitor subscription metrics

---

## Troubleshooting

### Common Issues:

**Products Not Loading:**
- Ensure product IDs match exactly in code and App Store Connect
- Products must be in "Ready to Submit" status
- Wait 24 hours after creating products
- Check Agreements, Tax, and Banking are complete

**Sandbox Testing Not Working:**
- Sign out of App Store on device
- Sign in with Sandbox account in Settings → App Store → Sandbox Account
- Delete and reinstall app

**Receipt Validation Failing:**
- Use sandbox receipt validation endpoint for testing
- Use production endpoint for release

**Subscription Not Activating:**
- Check StoreKit logs in Console.app
- Verify transaction is being finished properly
- Check subscription status in App Store Connect

---

## Support Resources

- **App Store Connect:** https://appstoreconnect.apple.com
- **In-App Purchase Programming Guide:** https://developer.apple.com/in-app-purchase/
- **StoreKit Documentation:** https://developer.apple.com/documentation/storekit
- **Subscription Best Practices:** https://developer.apple.com/app-store/subscriptions/

---

## Next Steps

1. ✅ Complete this setup in App Store Connect
2. ✅ Test with StoreKit Configuration file locally
3. ✅ Test with Sandbox tester
4. ✅ Submit for TestFlight beta testing
5. ✅ Gather beta feedback
6. ✅ Submit for App Store review
7. ✅ Launch! 🚀
