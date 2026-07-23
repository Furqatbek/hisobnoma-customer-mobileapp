# CODING AGENTS: READ THIS FIRST

This is a **handoff bundle** from Claude Design (claude.ai/design).

A user mocked up designs in HTML/CSS/JS using an AI design tool, then exported this bundle so a coding agent can implement the designs for real.

## What you should do — IMPORTANT

**Read the chat transcripts first.** There are 1 chat transcript(s) in `chats/`. The transcripts show the full back-and-forth between the user and the design assistant — they tell you **what the user actually wants** and **where they landed** after iterating. Don't skip them. The final HTML files are the output, but the chat is where the intent lives.

**Read `project/Hisobnoma Shop Prototype.html` in full.** The user had this file open when they triggered the handoff, so it's almost certainly the primary design they want built. Read it top to bottom — don't skim. Then **follow its imports**: open every file it pulls in (shared components, CSS, scripts) so you understand how the pieces fit together before you start implementing.

**If anything is ambiguous, ask the user to confirm before you start implementing.** It's much cheaper to clarify scope up front than to build the wrong thing.

## About the design files

The design medium is **HTML/CSS/JS** — these are prototypes, not production code. Your job is to **recreate them pixel-perfectly** in whatever technology makes sense for the target codebase (React, Vue, native, whatever fits). Match the visual output; don't copy the prototype's internal structure unless it happens to fit.

**Don't render these files in a browser or take screenshots unless the user asks you to.** Everything you need — dimensions, colors, layout rules — is spelled out in the source. Read the HTML and CSS directly; a screenshot won't tell you anything they don't.

## Bundle contents

- `README.md` — this file
- `chats/` — conversation transcripts (read these!)
- `project/` — the `Mobile Shop Prototype` project files (HTML prototypes, assets, components)

---

# Implementation notes (Flutter app in `lib/`)

## Payment & checkout flow (cash / card)

- **Checkout** (`lib/screens/cart.dart`) — collects name, phone, region/village **and a
  required address**; prices the cart via the server (`/web/cart/price`) so shown promotions
  are real; supports a **coupon** field (`/web/cart/validate-coupon`) and **cashback**
  redemption (`/web/me/loyalty`). The order is sent with `paymentMethod`, `address`,
  `couponCode` and `pointsToSpend`. Out-of-stock cart items are re-checked on open and block
  ordering.
- **Online payment** is gated by `ApiConfig.onlinePaymentEnabled`
  (`--dart-define=ONLINE_PAYMENT=true`). While off — the backend is **cash-on-delivery only**
  and ignores `paymentMethod` (see `MOBILE_SHOP_API.md`) — checkout shows **no method
  selector** and orders go straight to success as CASH. While on, a «Тўлов усули» selector
  appears (CASH / online CARD) and card orders go to **the payment screen**
  (`lib/screens/payment.dart`): provider list (Payme / Click / Uzum Bank), opens the checkout
  URL externally, then polls status (every 5 s for ~3 min, on app resume, manual button).
  «Кейинроқ тўлайман» always falls through, and a `503 PAYMENT_NOT_CONFIGURED` degrades to
  pay-on-delivery, so a missing provider never blocks ordering.
- **Order recovery** — every placed order is remembered locally (`LocalOrderRef`), so a guest
  can find/track/pay it from the status screen's «Сўнгги буюртмалар» list after a restart.
- **Order cards** (`lib/screens/account.dart`) — payment pill (Тўланган / Тўланмаган /
  Қайтарилган), full receipt rows (delivery, discount, coupon, spent cashback) and a «Тўлаш»
  button on unpaid card orders (when online payment is enabled).
- **Wallet QR** (`lib/screens/extras.dart`) shows a real scannable code only when the API
  exposes a customer code + tenant slug; otherwise an honest "tayyorlanmoqda" placeholder.

> **Backend team:** the full, prioritized spec (new endpoints, new fields,
> security requirements, checklist) lives in
> [`docs/BACKEND_REQUIREMENTS.md`](docs/BACKEND_REQUIREMENTS.md). The table below
> is the short version.

### Backend contract consumed (all optional — UI degrades gracefully when absent)

| API | Purpose |
| --- | --- |
| `POST /web/orders` fields `paymentMethod`, `address`, `couponCode`, `pointsToSpend` | persist + echo on the order DTO |
| `POST /web/cart/price` | authoritative cart subtotal/discount/total shown at checkout |
| `POST /web/cart/validate-coupon` | validate a coupon and return its discount |
| `GET /web/me/loyalty` | cashback balance, `minRedeem`, `maxRedeemPercent` for redemption |
| `POST /web/orders/{n}/payment` body `{phone, provider, returnUrl?}` | create a payment; returns `{id, paymentUrl, status, provider, amount}` |
| `GET /web/payments/{id}` | payment status by opaque id: `PENDING \| PAID \| FAILED \| CANCELLED \| REFUNDED` |
| Order DTO field `paymentStatus` | drives the status pills and the pay-again button |

### Security notes / backend requirements

- **HTTPS only for payments.** Release builds refuse to start an online payment when
  `API_BASE_URL` isn't `https://`, and the app launches a provider checkout URL only if it is
  HTTPS (blocks `payme://`, `intent://`, `javascript:`, cleartext). Optionally pin hosts with
  `--dart-define=PAYMENT_HOSTS=checkout.paycom.uz,my.click.uz`.
- **No PII in URLs.** Payment status is polled by the opaque `id` from the create call; the
  phone is only ever sent in the create POST body. The backend should likewise treat order
  numbers as **non-secret** (they're sequential) — rate-limit `GET /web/orders/{n}?phone=…`
  and prefer an unguessable token over phone-as-auth.
- **Deep links (follow-up).** `PAYMENT_RETURN_URL` is forwarded to the provider, but reopening
  the app on redirect needs platform app-links (Android intent-filters / iOS associated
  domains) that aren't configured yet — until then the resume-check + polling is the path back.

Tests for the flow live in `test/payment_flow_test.dart`.
