# Backend request — enable the store-review account (blocks App Store release)

Paste the block below to the backend team / backend agent as-is. Verified
against production on 2026-08-26.

---

## PROMPT — copy from here

**Context.** Apple rejected the iOS app "Sheben N1" (submission
`a1179fa8-2dcf-4739-aee0-0c510404ed07`, reviewed 2026-08-25) under
**Guideline 2.1(a) — Information Needed**: the reviewer could not sign in, so
they could not reach the account areas (Профиль, Ҳамён, Севимлилар, Купонлар).
Google Play needs the same credentials in its "App access" section. This is the
only thing blocking the iOS release; the app binary itself passed review with no
functional complaints.

**Root cause.** The fixed-OTP review account documented in
`docs/api/MOBILE_SHOP_API.md` ("Store-review sign-in (fixed OTP)") is **not
enabled on production**. Reproduced twice, six days apart:

```bash
# 2026-08-20
curl -s -X POST "https://temurmchj.uz/api/v1/web/auth/verify" \
  -H "X-Tenant-ID: 1" -H "Content-Type: application/json" \
  -d '{"phone":"+998900000000","code":"123456"}'
# → 400 {"success":false,"message":"Тасдиқлаш коди нотўғри",
#        "error":{"code":"OTP_INVALID"}}

# 2026-08-26 (same call)
# → 400 {"error":{"code":"OTP_EXPIRED"}}
```

`request-otp` for that number returns `200 {"message":"Code sent"}`, i.e. it is
treated as an ordinary phone and a random code is generated — the fixed-code
path is inactive, which means `WEB_REVIEW_ACCOUNT_PHONE` /
`WEB_REVIEW_ACCOUNT_CODE` are unset (or hold different values) in the
production environment.

### Task 1 (blocking) — enable the review account on production

Set on the **production** deployment:

```
WEB_REVIEW_ACCOUNT_PHONE=+998900000000
WEB_REVIEW_ACCOUNT_CODE=123456
```

If you prefer different values, that's fine — just tell us the exact phone and
code and we'll update the store metadata instead (it's a metadata field in both
stores, no app rebuild needed).

Requirements (both stores re-verify this on **every** future update review, so
it must be permanent, not a one-off):

1. `POST /web/auth/verify` with that phone + code **always** succeeds and
   returns a customer token — no expiry, no single-use, no "code already used".
2. The account is **exempt from OTP rate limits** and the 5-codes/day cap
   (reviewers retry, and Apple/Google review from many IPs).
3. No real SMS is sent for that number.
4. It behaves as an ordinary customer otherwise. Ideally it already has
   **1–2 completed orders and a small cashback balance**, so the reviewer sees
   non-empty Профиль and Ҳамён screens instead of empty states.
5. `GET /web/me` for it returns `customerCode` + `tenantSlug` (needed for the
   wallet QR screen to render).

**Please confirm when it is deployed** — we will verify with a live call before
replying to Apple, and we do not want to reply twice.

### Task 2 (important, likely data entry not code) — publish the catalog

Production currently exposes **one product and one category**:

```bash
curl -s "https://temurmchj.uz/api/v1/web/catalog/products?page=0&size=5" \
  -H "X-Tenant-ID: 1"
# → totalElements: 1  ("Каракалпок Семент 550")
curl -s "https://temurmchj.uz/api/v1/web/catalog/categories" -H "X-Tenant-ID: 1"
# → [{"id":5,"name":"Семент"}]
```

A near-empty shop reads as "broken/incomplete" to a store reviewer and doesn't
match our submitted screenshots (which show шағал / қум / цемент). Please
publish the real range for tenant 1 — or, if this is admin-panel data entry
rather than backend work, tell us who owns it so we can chase them directly.

Products sold by weight should carry `fractional: true` and a sensible `step`
(e.g. `0.5` for tonnes) — the app already renders a decimal quantity stepper
for those.

### Definition of done

- [ ] The verify call above returns a token on production (please paste the
      output).
- [ ] The review account is exempt from OTP throttling and its code never
      expires.
- [ ] Catalog for tenant 1 shows the real product range (or the owner of that
      task is identified).

### Already confirmed working — no action needed

- `DELETE /web/me` (account deletion) — implemented, wired into the app.
- Privacy policy hosted at `https://temurmchj.uz/privacy` — returns 200.
- Order history parity (`paymentMethod` / `paymentStatus` / `address`).
- HTTPS, error envelope, rate limiting, fractional product fields.

## PROMPT — copy to here
