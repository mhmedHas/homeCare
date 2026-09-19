# HomeCare Admin Payment Setup

## 1. Create the admin marker

In Firebase Console → Firestore Database, create:

`admins/{ADMIN_FIREBASE_UID}`

Fields:

```
active: true
```

The document ID must be the Firebase Authentication UID of the account that will use the admin dashboard.

The app checks this document before opening:

`/admin/payments`

Users cannot create or modify documents in `admins` from the app.

## 2. Admin payment flow

1. Client creates a booking.
2. Client chooses wallet or InstaPay.
3. Client transfers the full service amount.
4. Client sends the receipt through WhatsApp.
5. Booking becomes `awaiting_verification`.
6. Admin opens `/admin/payments`.
7. Admin checks the real receipt.
8. Admin presses `تأكيد الدفع`.
9. Firestore transaction atomically:
   - changes booking payment status to `verified`
   - changes booking status to `confirmed`
   - adds 85% to `nurseBalances/{nurseId}`
   - creates `nurseTransactions/{bookingId}`
10. If the same booking is confirmed again, the ledger document already exists and no second credit is made.

If the receipt is rejected, the payment becomes `rejected` and no balance is added.

## 3. Important security rule

The nurse balance is intentionally stored separately from the public `users` document:

`nurseBalances/{nurseId}`

This prevents other users from reading the financial balance through the normal user profile.

The Firestore rules also require the booking verification, balance change, and ledger entry to happen together in the same transaction.

## 4. Firestore rules

The repository contains `firestore.rules` and `firestore.indexes.json`.

Before deploying the rules to a production database, compare them with any existing Firestore rules in the Firebase Console and merge any rules needed by collections that are not represented in this ruleset.

After verification:

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

## 5. WhatsApp receiver

The payment screen currently uses:

`201124031904`

as the WhatsApp receiver. If the WhatsApp number is different from the InstaPay number, change the `_homeCareWhatsApp` constant in:

`lib/features/client/presentation/payment.dart`

The number must be in international format without `+`, spaces, or leading zero.

## 6. Payment destinations

- Wallet: `01119684470`
- InstaPay: `01124031904`

Both numbers are displayed with a copy button in the payment screen.
