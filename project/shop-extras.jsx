// Notifications, Wallet (cashback QR), Coupons, Referrals

// ── Deterministic pseudo-QR (programmatic, seeded) ──────────
function PseudoQR({ seed = 'hisobnoma', size = 196 }) {
  const n = 25;
  let h = 2166136261;
  for (let i = 0; i < seed.length; i++) { h ^= seed.charCodeAt(i); h = Math.imul(h, 16777619); }
  const rand = () => {
    h ^= h << 13; h ^= h >>> 17; h ^= h << 5;
    return (h >>> 0) / 4294967295;
  };
  const m = size / n;
  const inFinder = (x, y) => (x < 8 && y < 8) || (x >= n - 8 && y < 8) || (x < 8 && y >= n - 8);
  const cells = [];
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      if (inFinder(x, y)) continue;
      if (rand() < 0.46) cells.push(x + '-' + y);
    }
  }
  const finder = (fx, fy, key) => (
    <g key={key}>
      <rect x={fx * m} y={fy * m} width={7 * m} height={7 * m} fill="none" stroke="#0B0B0C" strokeWidth={m} />
      <rect x={(fx + 2) * m} y={(fy + 2) * m} width={3 * m} height={3 * m} fill="#0B0B0C" />
    </g>
  );
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} role="img" aria-label="Ҳамён QR коди">
      <rect width={size} height={size} fill="#fff" />
      {cells.map(c => {
        const [x, y] = c.split('-').map(Number);
        return <rect key={c} x={x * m} y={y * m} width={m * 0.92} height={m * 0.92} fill="#0B0B0C" />;
      })}
      {finder(0.5, 0.5, 'f1')}
      {finder(n - 7.5, 0.5, 'f2')}
      {finder(0.5, n - 7.5, 'f3')}
    </svg>
  );
}

// ── Profile menu row ─────────────────────────────────────────
function MenuRow({ icon, label, detail, onClick, isLast }) {
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 12, width: '100%',
      minHeight: 52, padding: '0 14px', border: 'none', background: 'none',
      cursor: 'pointer', position: 'relative', textAlign: 'left',
      WebkitTapHighlightColor: 'transparent',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 8, background: T.accentDim,
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
      }}>{icon}</div>
      <span style={{ flex: 1, fontFamily: T.font, fontSize: 16.5, color: T.text, letterSpacing: -0.2 }}>{label}</span>
      {detail && <span style={{ fontFamily: T.font, fontSize: 14.5, color: T.sec, marginRight: 2 }}>{detail}</span>}
      {Ic.chevronR()}
      {!isLast && <div style={{ position: 'absolute', bottom: 0, left: 58, right: 0, height: 0.5, background: T.sep }}></div>}
    </button>
  );
}

// ── Notifications ────────────────────────────────────────────
function NotificationsScreen({ app }) {
  const { NOTIFICATIONS } = window.ShopData;
  const typeIcon = {
    order: Ic.box(T.accent, 20),
    cashback: Ic.qr(T.accent, 20),
    promo: Ic.ticket(T.accent, 20),
  };
  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <NavHeader title={tr('Билдиришномалар')} onBack={app.pop} />
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 40 }}>
        {NOTIFICATIONS.map((nt, i) => (
          <div key={nt.id} style={{
            display: 'flex', gap: 12, padding: '14px 16px',
            borderBottom: i < NOTIFICATIONS.length - 1 ? `0.5px solid ${T.sep}` : 'none',
            background: nt.unread ? 'rgba(13,148,136,0.04)' : 'transparent',
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 100, background: T.accentDim,
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>{typeIcon[nt.type]}</div>
            <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 3 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ fontFamily: T.font, fontSize: 15.5, fontWeight: 600, color: T.text, letterSpacing: -0.2, flex: 1 }}>
                  {tr(nt.title)}
                </span>
                {nt.unread && <span style={{ width: 8, height: 8, borderRadius: 100, background: T.accent, flexShrink: 0 }}></span>}
              </div>
              <div style={{ fontFamily: T.font, fontSize: 14.5, color: T.sec, lineHeight: 1.4, letterSpacing: -0.15, textWrap: 'pretty' }}>
                {tr(nt.body)}
              </div>
              <div style={{ fontFamily: T.font, fontSize: 12.5, color: T.ter, marginTop: 2 }}>{tr(nt.date)}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Wallet (cashback QR) — root tab ─────────────────────────
function WalletScreen({ app }) {
  const { WALLET, formatSum, formatPhone } = window.ShopData;

  if (!app.user) {
    return (
      <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '74px 16px 0' }}>
          <h1 style={{ margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700, letterSpacing: 0.2, color: T.text, lineHeight: '41px' }}>{tr('Ҳамён')}</h1>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 36px 140px' }}>
          <div style={{
            width: 84, height: 84, borderRadius: 100, background: T.accentDim,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Ic.qr(T.accent, 40)}</div>
          <div style={{ marginTop: 16, fontFamily: T.font, fontSize: 17, fontWeight: 600, color: T.text, letterSpacing: -0.25 }}>
            {tr('Кешбек ҳамёни')}
          </div>
          <div style={{ marginTop: 6, fontFamily: T.font, fontSize: 15, color: T.sec, textAlign: 'center', lineHeight: 1.45, letterSpacing: -0.2, textWrap: 'pretty' }}>
            {tr2(`Ҳар бир хариддан ${WALLET.cashbackRate} кешбек. QR ҳамёнингизни кўриш учун тизимга киринг.`, `Кешбэк ${WALLET.cashbackRate} с каждой покупки. Войдите, чтобы увидеть ваш QR-кошелёк.`)}
          </div>
          <BigButton style={{ marginTop: 22, width: 'auto', padding: '0 48px' }}
            onClick={() => app.push({ name: 'login' })}>{tr('Кириш')}</BigButton>
        </div>
      </div>
    );
  }

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 120 }}>
        <div style={{ padding: '74px 16px 0' }}>
          <h1 style={{ margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700, letterSpacing: 0.2, color: T.text, lineHeight: '41px' }}>{tr('Ҳамён')}</h1>
        </div>

        {/* balance */}
        <div style={{ padding: '16px 16px 0' }}>
          <div style={{
            background: T.accentDim, borderRadius: T.radiusCard, padding: '16px 18px',
            display: 'flex', flexDirection: 'column', gap: 4,
          }}>
            <span style={{ fontFamily: T.font, fontSize: 13.5, fontWeight: 600, color: T.accent, textTransform: 'uppercase', letterSpacing: 0.4 }}>
              {tr('Кешбек баланс')}
            </span>
            <span style={{ fontFamily: T.font, fontSize: 30, fontWeight: 700, color: T.text, letterSpacing: -0.5 }}>
              {formatSum(WALLET.balance)}
            </span>
            <span style={{ fontFamily: T.font, fontSize: 13.5, color: T.sec }}>
              {tr2(`Ҳар бир хариддан ${WALLET.cashbackRate} кешбек`, `Кешбэк ${WALLET.cashbackRate} с каждой покупки`)}
            </span>
          </div>
        </div>

        {/* QR card */}
        <div style={{ padding: '14px 16px 0' }}>
          <div style={{
            border: `1px solid ${T.sep}`, borderRadius: T.radiusCard,
            padding: '20px 16px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12,
          }}>
            <PseudoQR seed={'wallet-' + app.user.phone} size={196} />
            <div style={{ fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', fontSize: 13.5, color: T.sec, letterSpacing: 0.5 }}>
              {formatPhone(app.user.phone)}
            </div>
            <div style={{ fontFamily: T.font, fontSize: 14, color: T.sec, textAlign: 'center', lineHeight: 1.45, letterSpacing: -0.15, maxWidth: 280, textWrap: 'pretty' }}>
              {tr('Кассада QR кодни кўрсатинг — кешбек ҳамёнингизга ўтказилади')}
            </div>
          </div>
        </div>

        {/* transactions */}
        <div style={{ padding: '22px 16px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SectionHeader>{tr('Ҳаракатлар')}</SectionHeader>
          <div>
            {WALLET.transactions.map((tx, i) => (
              <div key={tx.id} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '12px 2px',
                borderBottom: i < WALLET.transactions.length - 1 ? `0.5px solid ${T.sep}` : 'none',
              }}>
                <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <span style={{ fontFamily: T.font, fontSize: 15, color: T.text, letterSpacing: -0.2 }}>{tr(tx.label)}</span>
                  <span style={{ fontFamily: T.font, fontSize: 13, color: T.ter }}>{tr(tx.date)}</span>
                </div>
                <span style={{
                  fontFamily: T.font, fontSize: 15.5, fontWeight: 600, whiteSpace: 'nowrap',
                  color: tx.amount > 0 ? T.green : T.text, fontVariantNumeric: 'tabular-nums',
                }}>{tx.amount > 0 ? '+' : '−'}{formatSum(Math.abs(tx.amount))}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Coupons ──────────────────────────────────────────────────
function CouponsScreen({ app }) {
  const { useState } = React;
  const { COUPONS } = window.ShopData;
  const [seg, setSeg] = useState('active');
  const items = COUPONS.filter(c => seg === 'active' ? !c.used : c.used);

  const copyCode = (code) => {
    try { navigator.clipboard.writeText(code); } catch (e) {}
    app.toast(tr('Код нусха олинди') + ': ' + code);
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <NavHeader title={tr('Купонлар')} onBack={app.pop} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '6px 16px 40px' }}>
        {/* segmented control */}
        <div style={{
          display: 'flex', background: T.fill, borderRadius: 10, padding: 2, marginBottom: 16,
        }}>
          {[['active', 'Фаол'], ['used', 'Ишлатилган']].map(([id, label]) => (
            <button key={id} onClick={() => setSeg(id)} style={{
              flex: 1, height: 34, borderRadius: 8, border: 'none', cursor: 'pointer',
              background: seg === id ? '#fff' : 'transparent',
              boxShadow: seg === id ? '0 1px 4px rgba(0,0,0,0.10)' : 'none',
              fontFamily: T.font, fontSize: 14.5, fontWeight: seg === id ? 600 : 500,
              color: seg === id ? T.text : T.sec, letterSpacing: -0.15,
              transition: 'background 0.18s ease, box-shadow 0.18s ease',
              WebkitTapHighlightColor: 'transparent',
            }}>{tr(label)}</button>
          ))}
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {items.length === 0 && (
            <div style={{ fontFamily: T.font, fontSize: 15, color: T.sec, textAlign: 'center', padding: '32px 0' }}>
              {tr('Ҳозирча купонлар йўқ')}
            </div>
          )}
          {items.map(c => (
            <div key={c.id} style={{
              display: 'flex', border: `1px solid ${T.sep}`, borderRadius: T.radiusCard,
              overflow: 'hidden', opacity: c.used ? 0.55 : 1, background: T.bg,
            }}>
              <div style={{
                width: 92, flexShrink: 0, background: c.used ? 'rgba(120,120,128,0.10)' : T.accentDim,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                borderRight: `1px dashed ${c.used ? 'rgba(60,60,67,0.25)' : 'rgba(13,148,136,0.35)'}`,
                padding: '18px 8px',
              }}>
                <span style={{
                  fontFamily: T.font, fontSize: 16, fontWeight: 700, textAlign: 'center',
                  color: c.used ? T.sec : T.accent, letterSpacing: -0.3, lineHeight: 1.2,
                }}>{tr(c.value)}</span>
              </div>
              <div style={{ flex: 1, padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 4, minWidth: 0 }}>
                <span style={{ fontFamily: T.font, fontSize: 15, fontWeight: 600, color: T.text, letterSpacing: -0.2 }}>{tr(c.title)}</span>
                <span style={{ fontFamily: T.font, fontSize: 13, color: T.sec }}>{tr(c.until)}</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                  <span style={{
                    fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', fontSize: 13,
                    fontWeight: 600, color: T.text, background: T.fill, borderRadius: 6,
                    padding: '3px 8px', letterSpacing: 0.5,
                  }}>{c.code}</span>
                  {!c.used && (
                    <button onClick={() => copyCode(c.code)} aria-label="Нусха олиш" style={{
                      border: 'none', background: 'none', cursor: 'pointer', padding: 4,
                      display: 'flex', WebkitTapHighlightColor: 'transparent',
                    }}>{Ic.copy()}</button>
                  )}
                  {c.used && (
                    <span style={{ fontFamily: T.font, fontSize: 12, fontWeight: 600, color: T.sec }}>{tr2('Ишлатилган', 'Использован')}</span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── Referrals ────────────────────────────────────────────────
function ReferralsScreen({ app }) {
  const { REFERRAL, formatSum } = window.ShopData;

  const copyCode = () => {
    try { navigator.clipboard.writeText(REFERRAL.code); } catch (e) {}
    app.toast(tr('Код нусха олинди'));
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <NavHeader title={tr('Дўстларни таклиф қилиш')} onBack={app.pop} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '10px 16px 40px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0 }}>
          <div style={{
            width: 76, height: 76, borderRadius: 100, background: T.accentDim,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Ic.gift(T.accent, 36)}</div>
          <p style={{
            margin: '16px 0 0', fontFamily: T.font, fontSize: 15.5, color: T.text,
            textAlign: 'center', lineHeight: 1.5, letterSpacing: -0.2, maxWidth: 300, textWrap: 'pretty',
          }}>
            {tr2('Дўстингиз сизнинг кодингиз билан биринчи буюртма берса — иккалангизга', 'Если друг сделает первый заказ с вашим кодом — вы оба получите')}{' '}
            <strong>{formatSum(REFERRAL.bonus)}</strong> {tr2('кешбек', 'кешбэка')}
          </p>

          {/* code card */}
          <button onClick={copyCode} style={{
            marginTop: 20, display: 'flex', alignItems: 'center', gap: 10,
            background: T.fill, border: `1px dashed rgba(60,60,67,0.30)`, borderRadius: 12,
            padding: '14px 22px', cursor: 'pointer', WebkitTapHighlightColor: 'transparent',
          }}>
            <span style={{
              fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', fontSize: 20,
              fontWeight: 700, color: T.text, letterSpacing: 1.5,
            }}>{REFERRAL.code}</span>
            {Ic.copy(T.sec, 18)}
          </button>

          <BigButton style={{ marginTop: 18 }} onClick={() => app.toast(tr('Telegram орқали улашиш'))}>
            {tr('Telegram орқали улашиш')}
          </BigButton>

          {/* stats */}
          <div style={{
            marginTop: 24, width: '100%', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12,
          }}>
            <div style={{ border: `1px solid ${T.sep}`, borderRadius: T.radiusCard, padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 3 }}>
              <span style={{ fontFamily: T.font, fontSize: 24, fontWeight: 700, color: T.text, letterSpacing: -0.4 }}>{REFERRAL.invited}</span>
              <span style={{ fontFamily: T.font, fontSize: 13.5, color: T.sec, letterSpacing: -0.1 }}>{tr('Таклиф қилинган')}</span>
            </div>
            <div style={{ border: `1px solid ${T.sep}`, borderRadius: T.radiusCard, padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 3 }}>
              <span style={{ fontFamily: T.font, fontSize: 24, fontWeight: 700, color: T.green, letterSpacing: -0.4 }}>+{formatSum(REFERRAL.earned)}</span>
              <span style={{ fontFamily: T.font, fontSize: 13.5, color: T.sec, letterSpacing: -0.1 }}>{tr('Олинган бонус')}</span>
            </div>
          </div>

          {/* how it works */}
          <div style={{ marginTop: 24, width: '100%', display: 'flex', flexDirection: 'column', gap: 12 }}>
            <SectionHeader>{tr('Қандай ишлайди')}</SectionHeader>
            {[
              'Кодингизни дўстингизга юборинг',
              'Дўстингиз буюртма беришда кодни киритади',
              'Иккалангиз ҳам кешбек оласиз',
            ].map((step, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{
                  width: 26, height: 26, borderRadius: 100, background: T.accentDim, flexShrink: 0,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: T.font, fontSize: 13.5, fontWeight: 700, color: T.accent,
                }}>{i + 1}</span>
                <span style={{ fontFamily: T.font, fontSize: 15, color: T.text, letterSpacing: -0.2 }}>{tr(step)}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  PseudoQR, MenuRow, NotificationsScreen, WalletScreen, CouponsScreen, ReferralsScreen,
});
