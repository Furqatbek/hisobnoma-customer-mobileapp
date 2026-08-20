# Backend request — customer account deletion (`DELETE /web/me`)

**From:** customer mobile app team
**Priority:** P0 — blocks the App Store submission
**Why:** Apple **Guideline 5.1.1(v)** requires any app that supports account
creation to also offer **in-app account deletion**. Sheben N1 has SMS sign-in
but no way to delete an account, so a submission today gets rejected. Google
Play's Data Safety form also asks for a deletion path, and we currently answer
it with "по запросу" — this endpoint lets us answer it properly.

The client work (a "Delete account" action in Профиль, with confirmation) is
ready to implement as soon as the endpoint exists.

---

## 1. Endpoint

```
DELETE /api/v1/web/me
Authorization: Bearer <customer token>      // required
X-Tenant-ID: <tenant>
```

No request body. **Only the authenticated customer's own account** may be
deleted — the id must come from the token, never from a parameter.

### Responses

| Status | Body | Client behaviour |
| --- | --- | --- |
| `200` / `204` | `{ "success": true }` | Wipe local session + cached data, return to catalog, show a confirmation |
| `401 UNAUTHORIZED` | standard error body | Treat as already signed out |
| `409` (see §3) | `{ "success": false, "error": { "code": "...", "message": "<uz, user-safe>" } }` | Show `message` as-is |
| `429 TOO_MANY_REQUESTS` | standard | Show the throttling message |

Please keep the documented error envelope
(`{success:false, error:{code, message}}`) so the app can display `message`
directly.

---

## 2. What should happen to the data

The customer owns data across several areas (all reachable today under
`/web/me/**`). Our suggestion — final call is yours, since order records have
accounting implications:

| Data | Suggested treatment |
| --- | --- |
| Customer record (`phone`, `name`, `customerCode`) | **Anonymise or delete.** If the row must survive for order integrity, null the name and replace the phone with a non-reusable placeholder so it can't be matched to a person. |
| Auth / OTP records, sessions, tokens | **Delete.** All existing tokens must stop working immediately. |
| Device tokens (`/web/me/device-token`) | **Delete** (no pushes after deletion). |
| Wishlist, notifications, coupons issued to the customer | **Delete.** |
| Loyalty balance + ledger | **Delete or zero out.** Balance is forfeited on deletion — please confirm, we'll state it in the confirmation dialog. |
| Referral code + stats | **Delete**, but keep already-granted bonuses of *other* customers intact. |
| **Orders** | **Keep** for accounting/fulfilment, but **detach from the customer** and anonymise the personal fields (name/phone/address) once the order is completed or cancelled. |

### Blocking conditions (if any)
If an account with **active orders** (status `NEW` / `CONFIRMED` / `DELIVERING`)
must not be deleted, return `409` with a stable code — e.g.
`ACCOUNT_HAS_ACTIVE_ORDERS` — and a user-safe `message` in Uzbek. We'll show it
verbatim and tell the customer to wait until delivery completes. If you'd
rather allow deletion regardless, that's fine too — just tell us which, so the
UI copy matches reality.

---

## 3. Questions we need answered (short)

1. **Immediate or delayed?** Instant deletion, or a grace period (e.g. 30 days,
   cancellable by signing in again)? Both are Apple-acceptable; the dialog
   wording differs, so we need to know which.
2. **Loyalty balance** — forfeited on deletion? (We'll warn the user if so.)
3. **Active orders** — blocked (`409`) or allowed?
4. **Re-registration** — can the same phone sign up again afterwards, and does
   it start with a clean balance/history? (Expected: yes, clean.)
5. Any deletion audit/record you need us to pass (e.g. a reason string)?
   We'd rather not ask the user for one unless you need it.

---

## 4. Also needed for store review (separate, small)

Both stores' reviewers must be able to sign in, but they can't receive a
`+998` SMS. Please provision a **fixed-OTP review account**:

- phone `+998 90 000 00 00`, code always `123456`
- exempt from OTP rate limits and the 5-codes/day cap
- an ordinary customer otherwise (may hold sample orders/cashback)

This value goes into Google Play's "App access" and Apple's "App Review
Information". It's checked on **every** update review, so it needs to stay
stable.

---

## 5. Definition of done

- `DELETE /api/v1/web/me` implemented per §1–§2, documented in
  `docs/api/MOBILE_SHOP_API.md`.
- Answers to §3 so the client copy is accurate.
- Fixed-OTP review account live (§4).

Once we have the endpoint we'll ship the in-app flow: Профиль → «Аккаунтни
ўчириш» → confirmation dialog listing exactly what is deleted → call → local
wipe → back to catalog.
