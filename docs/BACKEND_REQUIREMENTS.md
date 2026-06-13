# Backend Requirements — Hisobnoma Customer App

This lists everything the customer mobile app now **expects from the backend**:
brand-new endpoints, new request/response fields on existing endpoints, and
security/robustness requirements. It reflects the client as implemented — every
field name below matches what the app sends or parses.

The app degrades gracefully where it can (missing optional fields render as
"absent" rather than crashing), but the items marked **P0/P1** must be
implemented for the corresponding features to actually work.

---

## Status — ✅ implemented on the backend

The backend team reports **all of §1–§7 implemented** (authoritative API docs:
`docs/API.md` + Postman collection in the backend repo). The client is aligned.
Notes from the rollout:

- **§1 payment endpoints exist but providers aren't live yet** in staging:
  `POST /web/orders/{n}/payment` returns **`503 PAYMENT_NOT_CONFIGURED`**. The
  client treats this as graceful degradation (toast + pay-on-delivery), and the
  online-payment screen stays gated behind the `ONLINE_PAYMENT` **build flag** —
  flip it on (`--dart-define=ONLINE_PAYMENT=true`) once real merchant
  credentials are wired; no other client change needed.
- **§3 correction applied:** `discountTotal` is **promotions only** and
  `couponDiscount` is a **separate, non-overlapping** amount — the client shows
  both as distinct lines (it had wrongly assumed overlap; now fixed).
- **§6 error codes** are consumed: the app shows `message` directly and falls
  back by status. Known `error.code`s: `COUPON_INVALID`, `PRODUCT_UNAVAILABLE`,
  `OTP_INVALID`, `OTP_EXPIRED`, `INVALID_PHONE`, `ORDER_ALREADY_PAID`,
  `PAYMENT_NOT_CONFIGURED`, `TOO_MANY_REQUESTS`, `NOT_FOUND`, `UNAUTHORIZED`.
- **§7 fractional** is live client-side: products with `fractional: true` +
  `step` use a decimal stepper; order lines send decimal `quantity`.

**Cross-team open items (neither blocks the other):**
- *Backend:* wire the real Payme/Click provider webhooks (needs merchant +
  sandbox credentials); until then payments are confirmed by staff.
- *Client:* configure Android App Links / iOS Universal Links so the
  `returnUrl` deep-link can reopen the app — **not blocking**, polling is the
  primary confirmation path.

The full spec below remains the field-level reference.

---

## Conventions (already in place)

- **Base path:** `…/api/v1`; customer endpoints live under `/web/...`.
- **Tenant header:** every request sends `X-Tenant-ID: <id>`.
- **Auth:** logged-in calls send `Authorization: Bearer <jwt>`. A `401` makes the
  app drop the session (and toast "session expired").
- **Success envelope:** the app unwraps `{ "success": true, "data": <payload> }`
  and reads `data`. Bare payloads also work.
- **Paging:** list endpoints return `{ "content": [...], "page": { "number",
  "totalPages", "last" } }`.
- **Errors:** non-2xx may include `{ "message": "...", "error": { "code": "..." } }`
  (see §6.4).
- **Phone:** E.164, e.g. `+998901234567`.

**Priority:** **P0** = blocks online card payments · **P1** = needed for correct
checkout / full UX · **P2** = hardening / future.

---

## 1. Online card payment — NEW endpoints (P0)

The app's card-payment flow is fully built but **gated off** until these ship
(client build flag `--dart-define=ONLINE_PAYMENT=true`). Until then "card" means
*pay the courier by card on delivery* and the online screen is skipped.

### 1.1 Create a payment
`POST /web/orders/{orderNumber}/payment`

Guest-authorised by the order's phone (same trust model as order lookup). Phone
is sent **in the body, never the query string**.

Request body:
```json
{ "phone": "+998901234567", "provider": "PAYME", "returnUrl": "https://…" }
```
- `provider` ∈ `PAYME` | `CLICK` | `UZUM`.
- `returnUrl` optional (app may omit it); see §1.3.

Response (`data`):
```json
{
  "id": "pay_abc123",
  "paymentUrl": "https://checkout.paycom.uz/…",
  "status": "PENDING",
  "provider": "PAYME",
  "amount": 33000
}
```
- **`id`** — opaque payment token used for polling (§1.2). Required. (The app
  also accepts `paymentId` as an alias, but please return `id`.)
- **`paymentUrl`** — provider checkout page. **Must be HTTPS** — the app refuses
  to open non-HTTPS, `payme://`, `intent://`, `javascript:` etc. (alias `url`
  accepted).
- `status` — see the status vocabulary in §1.2.

### 1.2 Poll payment status
`GET /web/payments/{paymentId}`

By the opaque `id` from §1.1 — **no phone / order number in the URL** (avoids PII
in access logs). The app polls this every 5s for ~3 min, on app-resume, and via a
manual button.

Response (`data`):
```json
{ "id": "pay_abc123", "status": "PAID", "provider": "PAYME", "amount": 33000 }
```
`status` vocabulary the app understands:
- `PENDING` — keep waiting.
- `PAID` — success → app marks the order paid and shows the receipt.
- `FAILED` / `CANCELLED` — terminal failure → app shows "try again".
- (`NONE` treated as pending.)

### 1.3 Provider integration (backend-internal)
- Integrate Payme / Click / Uzum Bank checkout + their **callbacks/webhooks** so
  `GET /web/payments/{id}` reflects the real outcome (the app relies on polling;
  it has no other signal).
- `returnUrl`: when present, redirect the customer back to it after payment.
  Reopening the app on that redirect also needs platform deep-links (Android
  App Links / iOS Universal Links) — **not yet configured client-side**, so for
  now polling is the path back. Coordinate the return domain when ready.

---

## 2. Order creation — new request fields (P1)

`POST /web/orders` — the app now sends these (in addition to the existing
`customerName`, `phone`, `regionId`, `villageId`, `note`, `lines`):

| Field | Type | Notes |
| --- | --- | --- |
| `paymentMethod` | `"CASH"` \| `"CARD"` | **Persist and echo** on the Order DTO (§3). |
| `address` | string | Free-text street / house / landmark. **Now required in the UI** — must be stored and shown to fulfilment. If you have a structured address model, tell us and we'll adapt. |
| `couponCode` | string | Now actually sent from checkout (was unused before). Apply server-side. |
| `pointsToSpend` | int | Cashback to redeem; see §5.3. Validate against balance + cap. |

`lines` items are `{ "catalogItemId": <int>, "quantity": <int> }` (integer
quantities today — see §7).

---

## 3. Order DTO — new response fields (P1)

The Order object (returned by create, `GET /web/orders/{n}`, and
`GET /web/me/orders`) must include:

| Field | Type | Drives |
| --- | --- | --- |
| `paymentMethod` | `"CASH"` \| `"CARD"` | Payment line on receipts/cards. |
| `paymentStatus` | `PAID` \| `PENDING` \| `NONE` \| `FAILED` \| `CANCELLED` \| `REFUNDED` | Status pill (Тўланган / Тўланмаган / Қайтарилган) and the "Тўлаш" pay-again button on unpaid card orders. **Set `REFUNDED` when a paid order is refunded/cancelled.** Omit/empty → no payment state shown (legacy-safe). |

Fields the app already reads and relies on (ensure they're present and that
`discountTotal` is the **aggregate** discount — the app shows one discount line
to avoid double-counting the coupon): `orderNumber`, `status`, `deliveryFee`,
`discountTotal`, `couponCode`, `couponDiscount`, `pointsSpent`, `totalAmount`,
`createdAt`, `lines[] { productName, quantity, unitPrice, lineTotal }`.

---

## 4. `GET /web/me` — wallet QR fields (P1)

The wallet shows a real scannable cashback QR **only** when these are present;
otherwise it shows an honest "QR код тайёрланмоқда" placeholder.

| Field | Type | Notes |
| --- | --- | --- |
| `customerCode` | string | Public loyalty id, e.g. `"WC-00001"`. |
| `tenantSlug` | string | Tenant slug for the deep link. |

The QR encodes `{walletQrBase}/{tenantSlug}/{customerCode}`. (Existing fields
`phone`, `name` still required.)

---

## 5. Confirm these existing endpoints (now actively used) (P1)

These already exist from the original integration but are **now consumed at
checkout**, so their correctness matters more:

### 5.1 `POST /web/cart/price`
Drives the checkout total (so shown promotions are real, not a client guess).
Body `{ "lines": [{catalogItemId, quantity}] }` → `{ subtotal, discountTotal,
total, appliedPromotions: [...] }`.

### 5.2 `POST /web/cart/validate-coupon`
Body `{ "code", "lines": [...] }` → `{ "valid": true, "discount": 5000 }` (or
`{ "valid": false }`). Powers the coupon field on checkout.

### 5.3 `GET /web/me/loyalty`
Used for cashback redemption at checkout. Must return `{ balance, enabled,
minRedeem, maxRedeemPercent, entries: [...] }`. The app caps redeemable points at
`min(balance, maxRedeemPercent% of goods total)` and sends the result as
`pointsToSpend` (§2) — **the server is authoritative and must re-validate**.

---

## 6. Security & robustness (P1 / P2)

### 6.1 HTTPS everywhere (P0 for payments)
The app refuses to start an online payment in release builds unless the API base
is `https://`, and only opens HTTPS provider URLs. Production must be TLS.

### 6.2 Order lookup is enumerable — rate-limit it (P1)
`GET /web/orders/{orderNumber}?phone=…` is authorised only by a 9-digit phone,
and order numbers are **sequential** (`WO-000042`). Please:
- **Rate-limit** this endpoint per IP/phone.
- Prefer an **unguessable order token** over phone-as-auth where feasible.

### 6.3 OTP request — server-side throttle (P1)
`POST /web/auth/request-otp` — the client throttles resends ~60s, but that's
best-effort UX only. The backend **must** enforce SMS-bomb protection
(per-phone/per-IP rate limits, daily caps). Return `429` when throttled (the app
shows a friendly "too many attempts" message).

### 6.4 User-facing error messages (P1)
On error responses, include a **localized, user-safe** `message`
(`{ "message": "Bu kupon eskirgan", "error": { "code": "COUPON_EXPIRED" } }`).
The app shows `message` directly; without it, it falls back to a generic message
by status (network / 5xx / 404 / 429). Don't return raw stack traces / technical
text in `message`.

---

## 7. Future: fractional quantities (P2)

The cart currently only expresses **integer** quantities, so products sold by
weight (e.g. 0.5 kg) can't be ordered. To support them we'd need, from the
backend:
- A `Product` field indicating the unit is fractional and its **step**
  (e.g. `{ "fractional": true, "step": 0.5 }` or a unit-type enum).
- Order line `quantity` accepting decimals (the app already reads
  `OrderLine.quantity` as a number; only cart *entry* is integer-bound today).

Until that exists the app stays integer-only by design.

---

## Quick checklist

- [ ] **P0** `POST /web/orders/{n}/payment` (create payment, returns `id` + HTTPS `paymentUrl`)
- [ ] **P0** `GET /web/payments/{id}` (status by opaque id)
- [ ] **P0** Payme / Click / Uzum integration + status webhooks
- [ ] **P0** TLS in production
- [ ] **P1** `POST /web/orders` accepts + stores `paymentMethod`, `address`, `couponCode`, `pointsToSpend`
- [ ] **P1** Order DTO returns `paymentMethod` + `paymentStatus` (incl. `REFUNDED`)
- [ ] **P1** `GET /web/me` returns `customerCode` + `tenantSlug`
- [ ] **P1** `/web/cart/price`, `/web/cart/validate-coupon`, `/web/me/loyalty` correct + authoritative
- [ ] **P1** Rate-limit OTP request and order lookup; return user-safe error `message`
- [ ] **P2** `Product` fractional-unit metadata + decimal order-line quantity
