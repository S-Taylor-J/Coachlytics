# Accounts setup (Phase 1)

The app **builds and runs without any of this**. Until `GoogleService-Info.plist` is in the
bundle, `CoachingManagerApp` skips `FirebaseApp.configure()`, `AuthService` reports
`.signedOut`, and every account action throws `AuthError.notConfigured`. Coachlytics itself
is fully usable in that state — the welcome screen's "Continue without an account" path is
the only one that works.

To turn accounts on, do these four things.

## 1. Create the Firebase project

1. <https://console.firebase.google.com> → **Add project** → name it `Coachlytics`.
2. **Add app** → iOS → bundle ID `com.ts.coachlytics`.
3. Download `GoogleService-Info.plist` and put it at
   `CoachingManager/Resources/GoogleService-Info.plist`.

The target uses a synchronized root group, so the file joins the build automatically — no
Xcode drag-and-drop needed. It is **not** a secret (it ships inside every copy of the app);
commit it. Security comes from the rules in step 3, not from hiding this file.

## 2. Enable sign-in providers

Firebase console → **Authentication** → **Sign-in method**:

- **Email/Password** → enable.
- **Apple** → enable.

For Apple you also need, in the [Apple Developer portal](https://developer.apple.com/account):

- **Certificates, Identifiers & Profiles** → the `com.ts.coachlytics` App ID →
  enable the **Sign in with Apple** capability.

`CoachingManager/CoachingManager.entitlements` already declares
`com.apple.developer.applesignin`, so once the App ID has the capability, automatic signing
picks it up. Simulator builds sign fine without it; device builds will not.

## 3. Deploy the Firestore rules

Create the Firestore database (**Firestore Database** → Create database → production mode),
then:

```sh
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules
```

The rules live in [`firebase/firestore.rules`](../firebase/firestore.rules). Skipping this
step is the most likely cause of "sign-up worked but no user document appeared" — locked
mode denies the write, and the app falls back to an auth-only profile rather than failing
loudly.

## 4. App Store Connect subscriptions (only needed for real purchases)

Local testing needs none of this: the scheme already points at
`CoachingManager/Resources/Coachlytics.storekit`, so the paywall works in the simulator with
StoreKit's test environment.

For sandbox and production, create an auto-renewing subscription group **Coachlytics Pro**
with two products whose IDs must match `EntitlementStore.ProductID`:

| Product ID | Duration |
|---|---|
| `com.ts.coachlytics.pro.monthly` | 1 month |
| `com.ts.coachlytics.pro.yearly` | 1 year |

`PaywallView` shows "Subscriptions aren't available right now" whenever the product fetch
comes back empty, which is the expected state before these exist.

---

## Known limitation carried into Phase 2

`EntitlementStore.refreshEntitlements()` mirrors the StoreKit result to
`users/{uid}.entitlement`, and the rules currently let the client write that field. That is
fine while nothing is gated, but it means a determined user could grant themselves `pro`.
Before any paid feature actually protects server data, move that write into a Cloud Function
driven by App Store Server Notifications and remove `entitlement` from the client-writable
fields.
