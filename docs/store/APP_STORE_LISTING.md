# App Store — "Sheben N1" listing pack

Everything App Store Connect asks for, ready to paste. Assets are in
`assets/store/`. The binary must be built on a Mac (or via the CI workflow in
`.github/workflows/ios-build.yml`) — see §5.

---

## 1. Prerequisites (one-time)

| Item | Value / note |
| --- | --- |
| Apple Developer Program | $99/year — required for TestFlight and the store |
| Bundle ID | `uz.temurmchj.sheben` — register in Certificates, IDs & Profiles → Identifiers |
| App name (Connect) | `Sheben N1` |
| Primary language | Uzbek (add Russian as an additional localization) |
| SKU | `sheben-n1` (internal only, any unique string) |
| Capabilities | none required today (no push/IAP/sign-in-with-Apple yet) |

## 2. App information

- **Category:** Primary *Shopping*; Secondary *Business* (optional).
- **Content rights:** does not contain third-party content.
- **Age rating questionnaire:** answer **None / No** to everything → rating **4+**.
- **Privacy policy URL:** `https://temurmchj.uz/privacy`
  (page source: `docs/store/privacy-policy.html` — same one used for Play).

## 3. Version information (1.0)

**Promotional text (≤170 chars, uz):**
```
Шағал, қум ва цементни телефонингиздан буюртма қилинг. Тонна ҳисобида харид,
тез етказиб бериш ва ҳар бир хариддан кешбек.
```

**Description (uz):**
```
Sheben N1 — TEMUR MCHJ нинг қурилиш материаллари дўкони. Шағал, қум, цемент
ва бошқа материалларни телефонингиздан буюртма қилинг — биз етказиб берамиз.

ИМКОНИЯТЛАР
• Каталог — нархлар, чегирмалар ва мавжудлик ҳар доим долзарб
• Тонна ҳисобида харид — 0,5 тонна қадам билан керакли миқдорни танланг
• Сават ва буюртма — туман бўйича етказиб бериш, манзил ва изоҳ билан
• Буюртмани кузатиш — рақам ва телефон орқали ҳолатни текширинг
• Кешбек ҳамёни — ҳар бир хариддан бонус, кассада QR код орқали
• Купонлар ва дўстларни таклиф қилиш дастури
• SMS орқали тез кириш — парол керак эмас

Тўлов ҳозирча етказиб берилганда нақд пулда қабул қилинади.

TEMUR MCHJ, Тошкент.
```

**Description (ru):** same text as the Play listing
(`docs/store/PLAY_LISTING.md` §2, full description ru).

**Keywords (≤100 chars):**
```
шағал,қум,цемент,қурилиш,материал,доставка,щебень,песок,стройматериалы,Тошкент
```

**Support URL:** `https://temurmchj.uz` · **Marketing URL:** optional.
**Copyright:** `2026 TEMUR MCHJ`.

## 4. Media

- **App icon:** already inside the binary (1024×1024, no alpha) —
  `assets/icon/app_icon.png` if Connect asks separately.
- **iPhone 6.7" screenshots (required):** `assets/store/screenshots/iphone67/`
  (1290×2796) — one set covers all iPhone sizes.
- **iPad 13" screenshots (required, app runs on iPad):**
  `assets/store/screenshots/ipad13/` (2048×2732).

## 5. Build & upload the binary (Mac required)

**Option A — build on a Mac**
```bash
git clone <repo> && cd hisobnoma-customer-mobileapp
flutter build ipa --release
# then: open build/ios/archive/Runner.xcarchive → Xcode Organizer
#       → Distribute App → App Store Connect → Upload
```

**Option B — build in CI, sign on a Mac**
Run the `iOS build` workflow (Actions tab) → download the
`sheben-n1-ios-xcarchive` artifact → unzip → double-click the `.xcarchive` →
Xcode Organizer → Distribute App. No Flutter setup needed on that Mac.

**Option C — fully automated (later):** add an App Store Connect API key as
repo secrets and extend the workflow to sign + upload with `xcrun altool`.

After upload the build appears in Connect within ~15 minutes (processing).

## 6. App Privacy (Connect → App Privacy)

Same substance as the Play data-safety form:
- **Contact Info → Phone Number** — App Functionality, linked to user, not used for tracking.
- **Contact Info → Name** — App Functionality, linked to user.
- **Contact Info → Physical Address** — App Functionality, linked to user (delivery).
- **Purchases → Purchase History** — App Functionality, linked to user.
- **No** data used for tracking; **no** third-party advertising; no location, no contacts.
- Account deletion: state that users can request deletion via the contact in
  the privacy policy. (Apple requires in-app account deletion for apps with
  account creation — see §8.)

## 7. App Review Information

- **Sign-in required:** Yes.
- **Demo account:** phone `+998 90 000 00 00`, code `123456`
  (fixed-OTP review account — must be provisioned by the backend team and
  exempt from SMS rate limits).
- **Notes for the reviewer:**
```
Browsing the catalog, the cart and placing an order work without signing in
(guest checkout). Sign-in is SMS OTP only: Профиль → Кириш → enter
+998 90 000 00 00 → Код юбориш → enter 123456 → Тасдиқлаш. No SMS is sent for
this test number; the code is always 123456.

Signed-in areas: Профиль (order history), Ҳамён (cashback + QR code),
Севимлилар (wishlist), Купонлар (coupons).

Language can be switched in Профиль → Тил (Uzbek / Russian).
Payment is cash on delivery only; online card payment is disabled in this
version, so no purchase is required to review the app.
```

## 8. Known Apple-specific follow-ups

- **Account deletion (Guideline 5.1.1(v)):** apps that let users create an
  account must offer in-app account deletion. The app has sign-in but no
  delete-account action yet — Apple may reject on this. Fix = one profile
  screen action calling a backend delete endpoint (needs a backend endpoint;
  not required by Google).
- **Guest-first is a plus:** because ordering works without an account, the
  reviewer can exercise the core flow even before signing in.
- **No push notifications yet**, so no APNs configuration is needed for 1.0.
