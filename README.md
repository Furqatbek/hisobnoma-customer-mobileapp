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

## Payment flow (cash / card)

- **Checkout** (`lib/screens/cart.dart`) — a «Тўлов усули» section offers CASH or CARD; the
  choice is sent as `paymentMethod` on `POST /web/orders` and the last used method is the
  next checkout's default (SharedPreferences).
- **Payment screen** (`lib/screens/payment.dart`) — card orders continue here: provider list
  (Payme / Click / Uzum Bank), opens the provider's checkout URL externally, then polls the
  status — every 5 s for ~3 min, on app resume, and via a manual button. «Кейинроқ тўлайман»
  always falls through (the courier can take the payment), so a missing backend never blocks
  ordering.
- **Order cards** (`lib/screens/account.dart`) — payment pill (Тўланган / Тўланмаган /
  Қайтарилган), full receipt rows (delivery, discount, coupon, spent cashback) and a «Тўлаш»
  button on unpaid card orders that reopens the payment screen (works for guests via the
  status-lookup phone).

### Backend contract consumed (all optional — UI degrades gracefully when absent)

| API | Purpose |
| --- | --- |
| `POST /web/orders` body field `paymentMethod: CASH \| CARD` | persist the chosen method; echo it on the order DTO |
| `POST /web/orders/{n}/payment` body `{phone, provider}` | create a payment; returns `{paymentUrl, status, provider, amount}` |
| `GET /web/orders/{n}/payment?phone=…` | payment status: `PENDING \| PAID \| FAILED \| CANCELLED \| REFUNDED` |
| Order DTO field `paymentStatus` | drives the status pills and the pay-again button |

Tests for the flow live in `test/payment_flow_test.dart`.
