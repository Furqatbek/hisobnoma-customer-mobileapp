# Apple review rejection — response plan (Submission a1179fa8)

**Rejected:** 2026-08-25 · version 1.0 (2) · two issues, **both fixable without
a new build**.

---

## Issue 1 — Guideline 2.3.6, Age Rating (fix yourself, 2 minutes)

Apple says the age-rating answers claim the app has **In-App Controls /
Age Assurance** (parental controls), which it doesn't.

**Fix:** App Store Connect → the app → **App Information** → **Age Rating →
Edit** → set **"Age Assurance"** (and any Parental/In-App Controls question)
to **None** → Save.

Nothing in the app needs to change — the app has no parental controls, and it
shouldn't claim any. Answer **None/No** to every question in that
questionnaire; the correct outcome for this app is a **4+** rating.

---

## Issue 2 — Guideline 2.1(a), reviewer can't sign in (needs the backend team)

**Root cause, verified against production on 2026-08-25:**

```
POST https://temurmchj.uz/api/v1/web/auth/verify
{"phone":"+998900000000","code":"123456"}
→ 400 {"error":{"code":"OTP_EXPIRED"}}      (on 08-20 it was OTP_INVALID)
```

The fixed-OTP review account documented in `MOBILE_SHOP_API.md` is **not
enabled on production** — the deployment is missing
`WEB_REVIEW_ACCOUNT_PHONE` / `WEB_REVIEW_ACCOUNT_CODE`. The reviewer entered
the credentials from the review notes, got "Тасдиқлаш коди нотўғри", and could
not reach Профиль / Ҳамён / Севимлилар / Купонлар.

### Message to send the backend team (urgent)

> Apple rejected the iOS app because the reviewer could not sign in
> (Guideline 2.1(a)). The fixed-OTP review account isn't active on production:
> verifying `+998900000000` with code `123456` returns `OTP_INVALID` /
> `OTP_EXPIRED`.
>
> Please set on the **production** deployment:
> `WEB_REVIEW_ACCOUNT_PHONE=+998900000000`
> `WEB_REVIEW_ACCOUNT_CODE=123456`
> (or tell us the values you prefer — we'll update the store metadata instead).
>
> Requirements: the code must work **every time**, be exempt from OTP rate
> limits and the daily cap, and remain stable — both stores re-check it on
> every future update review. Please confirm once deployed so we can verify
> with a live call before replying to Apple.

Same account is needed for Google Play's "App access" section, so this
unblocks both stores.

### Also worth fixing before re-review

Production currently exposes **1 product** ("Каракалпок Семент 550"). A
near-empty catalog looks broken to a reviewer and doesn't match the
screenshots. Ask the backend/ops team to publish the real range (шағал, қум,
цемент) for tenant 1.

---

## Reply to send in App Store Connect (Resolution Center)

**Send only after the backend confirms the account works** (we'll verify with a
live call first). Reply in English:

```
Hello,

Thank you for the review. Both issues are now resolved.

Guideline 2.3.6 — Age Rating
The Age Rating answers were incorrect on our side. The app contains no
parental controls and no age assurance features. We have corrected the Age
Rating questionnaire and set "Age Assurance" to None.

Guideline 2.1(a) — Sign in
The demo account was not active on our production server during the review.
This has been fixed and verified working today (26 August 2026).

Demo account
  Phone: +998 90 000 00 00
  Code:  123456

Sign-in steps:
  1. Open the app and go to the "Профил" tab (rightmost tab, person icon)
  2. Tap "Кириш" (Sign in)
  3. Enter the phone number above and tap "Код юбориш" (Send code)
  4. Enter 123456 and tap "Тасдиқлаш" (Confirm)

This number is configured on our server to always accept the code 123456, so
you do not need to receive an SMS. Step 3 is still required, as the app
requests a code before the entry field accepts input.

Additional notes
- The demo account is new, so Профил (order history) and Ҳамён (cashback) show
  empty states. To see the full flow you can place a test order: add any item
  to the cart, open Сават, tap "Буюртма бериш", and complete the form. Payment
  is cash on delivery, so no payment is taken and no purchase is required.
- Browsing the catalog and ordering also work without signing in (guest
  checkout).
- Signed-in areas: Профил (order history), Ҳамён (cashback and QR code),
  Севимлилар (wishlist), Купонлар (coupons).
- Account deletion is available in the app: Профил → "Аккаунтни ўчириш".
- The app language can be switched in Профил → Тил (Uzbek / Russian).

Please let us know if you need anything else to continue the review.

Thank you,
TEMUR MCHJ
```

After sending, the app returns to **Waiting for Review** — re-review after a
metadata fix is usually faster than the first submission (often <24h). No new
binary upload is needed for either issue.
