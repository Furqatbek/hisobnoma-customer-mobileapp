# Google Play — "Sheben N1" listing pack

Everything Play Console asks for when creating the app, ready to paste.
Assets referenced live in `assets/store/`.

---

## 1. Create app (Play Console → All apps → Create app)

| Field | Value |
| --- | --- |
| App name | `Sheben N1` |
| Default language | Uzbek — `uz` (add Russian `ru` as a translation afterwards) |
| App or game | App |
| Free or paid | Free |
| Declarations | tick both (Developer Program Policies + US export laws) |

## 2. Store listing (Grow → Store presence → Main store listing)

**App name:** `Sheben N1`

**Short description (uz, ≤80 chars):**
```
Шағал, қум ва цемент — онлайн буюртма ва тез етказиб бериш. Sheben N1.
```

**Short description (ru):**
```
Щебень, песок и цемент — онлайн-заказ с быстрой доставкой. Sheben N1.
```

**Full description (uz):**
```
Sheben N1 — TEMUR MCHJ нинг қурилиш материаллари дўкони. Шағал, қум,
цемент ва бошқа материалларни телефонингиздан буюртма қилинг — биз
етказиб берамиз.

ИМКОНИЯТЛАР
• Каталог — нархлар, чегирмалар ва мавжудлик ҳар доим долзарб
• Тонна ҳисобида харид — 0,5 тонна қадам билан керакли миқдорни танланг
• Сават ва буюртма — туман бўйича етказиб бериш, манзил ва изоҳ билан
• Буюртмани кузатиш — рақам ва телефон орқали ҳолатни текширинг
• Кешбек ҳамёни — ҳар бир хариддан бонус, кассада QR код орқали
• Купонлар ва дўстларни таклиф қилиш дастури
• SMS орқали тез кириш — парол керак эмас

Тўлов ҳозирча етказиб берилганда нақд пулда қабул қилинади. Карта
орқали онлайн тўлов тез орада қўшилади.

Саволлар учун: TEMUR MCHJ, Тошкент.
```

**Full description (ru):**
```
Sheben N1 — магазин строительных материалов компании TEMUR MCHJ.
Заказывайте щебень, песок, цемент и другие материалы с телефона — мы
доставим.

ВОЗМОЖНОСТИ
• Каталог — актуальные цены, скидки и наличие
• Покупка тоннами — выбирайте нужный объём с шагом 0,5 тонны
• Корзина и заказ — доставка по районам, адрес и комментарий
• Отслеживание заказа — статус по номеру и телефону
• Кешбэк-кошелёк — бонус с каждой покупки, QR-код на кассе
• Купоны и реферальная программа
• Быстрый вход по SMS — без пароля

Оплата пока принимается наличными при получении. Онлайн-оплата картой
появится в ближайшее время.

Вопросы: TEMUR MCHJ, Ташкент.
```

**Graphics:** app icon `assets/store/play_icon_512.png` · feature graphic
`assets/store/feature_graphic_1024x500.png` · screenshots from
`assets/store/screenshots/{phone,tablet7,tablet10}/`.

**Category:** Shopping. **Tags:** shopping / e-commerce.
**Contact email:** _(your support email — required)_. Website: `https://temurmchj.uz`.

## 3. Privacy policy (required)

URL to enter: `https://temurmchj.uz/privacy` — page source is in
[`docs/store/privacy-policy.html`](privacy-policy.html); ask the backend team
to serve it at that path (any stable public URL works).

## 4. Data safety form (Policy → App content → Data safety)

- Does your app collect or share user data? **Yes, collects.**
- Data encrypted in transit? **Yes** (HTTPS).
- Way to request deletion? **Yes** — via the contact in the privacy policy.
- Declare, all under **App functionality / Account management**, collected,
  **not shared**, **not optional** for ordering:
  - Personal info → **Phone number** (account sign-in + order contact)
  - Personal info → **Name**
  - Personal info → **Address** (delivery)
  - App activity → **In-app actions** = order history (App functionality)
- No location, no financial data (payment is cash on delivery), no ads data.

## 5. Other App-content declarations

- **Ads:** No ads.
- **App access:** "All or some functionality is restricted" → provide a note:
  browsing and checkout work without sign-in; sign-in uses SMS OTP. Ask the
  backend team for a **review test number with a fixed OTP** (e.g.
  `+998 90 000 00 00` / code `123456`) and enter it here so Google reviewers
  can test the account area.
- **Content rating questionnaire:** category *Utility/Shopping*; answer No to
  everything (no violence, no user-generated content, no gambling) → rating
  "Everyone / 3+".
- **Target audience:** 18 and over (construction-materials buyers).
- **News app:** No. **COVID app:** No. **Government app:** No.
- **Financial features:** None (cash on delivery).
- **Countries:** Uzbekistan (add more later if needed).

## 6. Upload & release

1. Release → **Testing → Internal testing** → Create release.
2. First upload triggers **Play App Signing** enrollment — accept (your
   keystore is the upload key; keep `upload-keystore.jks` + passwords safe).
3. Upload `app-release.aab` (built with `flutter build appbundle --release`,
   application id `uz.temurmchj.sheben`, version `1.0.0+1`).
4. Add your own Gmail as an internal tester → install via the opt-in link —
   internal testing is available within minutes.
5. When happy: Promote release → Production. First production review
   typically takes 1–7 days.
6. Every later upload must bump the build number in `pubspec.yaml`
   (`1.0.0+2`, `1.0.1+3`, …).
