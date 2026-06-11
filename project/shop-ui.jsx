// Hisobnoma Shop — design tokens + shared UI primitives

const T = {
  accent: '#0D9488',
  accentDim: 'rgba(13,148,136,0.10)',
  bg: '#FFFFFF',
  fill: 'rgba(120,120,128,0.10)',      // input / chip fill
  fill2: 'rgba(120,120,128,0.16)',
  text: '#0B0B0C',
  sec: 'rgba(60,60,67,0.60)',
  ter: 'rgba(60,60,67,0.33)',
  sep: 'rgba(60,60,67,0.12)',
  red: '#D63B2F',
  green: '#1E8A4C',
  font: '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, sans-serif',
  radiusCard: 14,
  radiusBtn: 24,
  radiusInput: 10,
};

// ── Icons (24px stroke, SF-symbol flavored, simple geometry) ─
const Ic = {
  search: (c = T.sec, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 20 20" fill="none">
      <circle cx="8.5" cy="8.5" r="6" stroke={c} strokeWidth="1.8"/>
      <path d="M13 13l4.5 4.5" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  grid: (c, s = 24) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <rect x="3.5" y="3.5" width="7" height="7" rx="2" stroke={c} strokeWidth="1.8"/>
      <rect x="13.5" y="3.5" width="7" height="7" rx="2" stroke={c} strokeWidth="1.8"/>
      <rect x="3.5" y="13.5" width="7" height="7" rx="2" stroke={c} strokeWidth="1.8"/>
      <rect x="13.5" y="13.5" width="7" height="7" rx="2" stroke={c} strokeWidth="1.8"/>
    </svg>
  ),
  cart: (c, s = 24) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M3 4h2.2l2.1 11.2a1.6 1.6 0 0 0 1.57 1.3h8.46a1.6 1.6 0 0 0 1.56-1.23L20.6 8H6" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
      <circle cx="9.6" cy="20.4" r="1.5" fill={c}/>
      <circle cx="17.2" cy="20.4" r="1.5" fill={c}/>
    </svg>
  ),
  person: (c, s = 24) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="8" r="4.2" stroke={c} strokeWidth="1.8"/>
      <path d="M4.5 20.4c1.4-3.6 4.2-5.4 7.5-5.4s6.1 1.8 7.5 5.4" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  chevronL: (c = T.text, s = 20) => (
    <svg width={s} height={s} viewBox="0 0 20 20" fill="none">
      <path d="M12.5 3.5L6 10l6.5 6.5" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  chevronR: (c = T.ter, s = 14) => (
    <svg width={s} height={s} viewBox="0 0 20 20" fill="none">
      <path d="M7.5 3.5L14 10l-6.5 6.5" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  check: (c = '#fff', s = 18) => (
    <svg width={s} height={s} viewBox="0 0 20 20" fill="none">
      <path d="M4 10.5l4.2 4.2L16.5 6" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  phone: (c = T.accent, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 20 20" fill="none">
      <path d="M4.2 3.2C4.6 2.8 5.3 2.8 5.7 3.2L7.8 5.3c.4.4.4 1 .05 1.45l-1 1.2a.9.9 0 0 0-.05 1.1 12.4 12.4 0 0 0 4.15 4.15.9.9 0 0 0 1.1-.05l1.2-1c.45-.35 1.05-.35 1.45.05l2.1 2.1c.4.4.4 1.1 0 1.5l-1 1c-.7.7-1.75.95-2.7.6-2.3-.85-4.5-2.3-6.4-4.2-1.9-1.9-3.35-4.1-4.2-6.4-.35-.95-.1-2 .6-2.7l1-1z" stroke={c} strokeWidth="1.6" strokeLinejoin="round"/>
    </svg>
  ),
  send: (c = T.accent, s = 18) => (
    <svg width={s} height={s} viewBox="0 0 20 20" fill="none">
      <path d="M17.5 2.5L9 11M17.5 2.5L12 17.5l-3-6.5-6.5-3 15-5.5z" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  bell: (c = T.text, s = 22) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M12 3.5c-3.3 0-5.5 2.5-5.5 5.6 0 4.2-1.6 5.6-2.5 6.6-.3.35-.05 1 .45 1h15.1c.5 0 .75-.65.45-1-.9-1-2.5-2.4-2.5-6.6 0-3.1-2.2-5.6-5.5-5.6z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/>
      <path d="M9.8 19.5a2.3 2.3 0 0 0 4.4 0" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  qr: (c, s = 24) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <rect x="3.5" y="3.5" width="7" height="7" rx="1.5" stroke={c} strokeWidth="1.8"/>
      <rect x="6" y="6" width="2" height="2" fill={c}/>
      <rect x="13.5" y="3.5" width="7" height="7" rx="1.5" stroke={c} strokeWidth="1.8"/>
      <rect x="16" y="6" width="2" height="2" fill={c}/>
      <rect x="3.5" y="13.5" width="7" height="7" rx="1.5" stroke={c} strokeWidth="1.8"/>
      <rect x="6" y="16" width="2" height="2" fill={c}/>
      <rect x="13.5" y="13.5" width="3" height="3" fill={c}/>
      <rect x="17.5" y="17.5" width="3" height="3" fill={c}/>
      <rect x="17.5" y="13.5" width="3" height="3" stroke={c} strokeWidth="1.4"/>
    </svg>
  ),
  ticket: (c = T.accent, s = 22) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M3.5 9V7A1.5 1.5 0 0 1 5 5.5h14A1.5 1.5 0 0 1 20.5 7v2a3 3 0 0 0 0 6v2a1.5 1.5 0 0 1-1.5 1.5H5A1.5 1.5 0 0 1 3.5 17v-2a3 3 0 0 0 0-6z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/>
      <path d="M14 6v2.5M14 11v2.5M14 15.5V18" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeDasharray="0.1 3.4"/>
    </svg>
  ),
  gift: (c = T.accent, s = 22) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <rect x="3.5" y="8" width="17" height="4.5" rx="1" stroke={c} strokeWidth="1.8"/>
      <path d="M5 12.5h14V19a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 19v-6.5z" stroke={c} strokeWidth="1.8"/>
      <path d="M12 8v12.5M12 8s-1-4-4-4a2 2 0 0 0 0 4h4zm0 0s1-4 4-4a2 2 0 0 1 0 4h-4z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/>
    </svg>
  ),
  globe: (c = T.accent, s = 22) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="8.5" stroke={c} strokeWidth="1.8"/>
      <ellipse cx="12" cy="12" rx="3.8" ry="8.5" stroke={c} strokeWidth="1.6"/>
      <path d="M3.5 12h17" stroke={c} strokeWidth="1.6" strokeLinecap="round"/>
    </svg>
  ),
  heart: (c = T.sec, s = 22) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none">
      <path d="M12 20.5s-7.8-4.9-9.3-9.8C1.6 7 4 4 7.1 4c2 0 3.8 1.1 4.9 2.9C13.1 5.1 14.9 4 16.9 4 20 4 22.4 7 21.3 10.7c-1.5 4.9-9.3 9.8-9.3 9.8z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/>
    </svg>
  ),
  heartFill: (c = '#D63B2F', s = 22) => (
    <svg width={s} height={s} viewBox="0 0 24 24">
      <path d="M12 20.5s-7.8-4.9-9.3-9.8C1.6 7 4 4 7.1 4c2 0 3.8 1.1 4.9 2.9C13.1 5.1 14.9 4 16.9 4 20 4 22.4 7 21.3 10.7c-1.5 4.9-9.3 9.8-9.3 9.8z" fill={c}/>
    </svg>
  ),
  copy: (c = T.sec, s = 16) => (
    <svg width={s} height={s} viewBox="0 0 20 20" fill="none">
      <rect x="7" y="7" width="10" height="10" rx="2.5" stroke={c} strokeWidth="1.6"/>
      <path d="M13 4.5V4a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h.5" stroke={c} strokeWidth="1.6"/>
    </svg>
  ),
  wifiOff: (c = T.ter, s = 44) => (
    <svg width={s} height={s} viewBox="0 0 44 44" fill="none">
      <path d="M7 17.5A21.4 21.4 0 0 1 22 11.5c5.7 0 10.9 2.25 15 6" stroke={c} strokeWidth="2.4" strokeLinecap="round"/>
      <path d="M12.5 24a13.6 13.6 0 0 1 9.5-3.9c3.7 0 7 1.5 9.5 3.9" stroke={c} strokeWidth="2.4" strokeLinecap="round"/>
      <circle cx="22" cy="31.5" r="2.6" fill={c}/>
      <path d="M8 6l28 32" stroke={c} strokeWidth="2.4" strokeLinecap="round"/>
    </svg>
  ),
  bag: (c = T.ter, s = 52) => (
    <svg width={s} height={s} viewBox="0 0 52 52" fill="none">
      <path d="M11 17h30l-2.2 24a3.2 3.2 0 0 1-3.2 2.9H16.4a3.2 3.2 0 0 1-3.2-2.9L11 17z" stroke={c} strokeWidth="2.6" strokeLinejoin="round"/>
      <path d="M18.5 22v-6.5a7.5 7.5 0 0 1 15 0V22" stroke={c} strokeWidth="2.6" strokeLinecap="round"/>
    </svg>
  ),
  box: (c = T.ter, s = 48) => (
    <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
      <path d="M6 15L24 6l18 9v18l-18 9-18-9V15z" stroke={c} strokeWidth="2.4" strokeLinejoin="round"/>
      <path d="M6 15l18 9 18-9M24 24v18" stroke={c} strokeWidth="2.4" strokeLinejoin="round"/>
    </svg>
  ),
  personBig: (c = T.ter, s = 72) => (
    <svg width={s} height={s} viewBox="0 0 72 72" fill="none">
      <circle cx="36" cy="36" r="33" stroke={c} strokeWidth="3"/>
      <circle cx="36" cy="28" r="10" stroke={c} strokeWidth="3"/>
      <path d="M16 60c3.4-8.8 10.5-13.5 20-13.5S52.6 51.2 56 60" stroke={c} strokeWidth="3" strokeLinecap="round"/>
    </svg>
  ),
};

// ── Image placeholder (neutral striped block + label) ───────
function ProductImage({ product, label, style = {}, radius = 12, fontSize = 11 }) {
  const name = label !== undefined ? label : (product ? product.name : '');
  return (
    <div aria-label={name} style={{
      background: '#F4F4F3',
      backgroundImage: 'repeating-linear-gradient(135deg, rgba(0,0,0,0.025) 0, rgba(0,0,0,0.025) 6px, transparent 6px, transparent 14px)',
      borderRadius: radius, overflow: 'hidden',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      border: '1px solid rgba(0,0,0,0.045)', boxSizing: 'border-box',
      ...style,
    }}>
      {name !== null && (
        <span style={{
          fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
          fontSize, color: 'rgba(60,60,67,0.40)', textAlign: 'center',
          padding: '0 10px', lineHeight: 1.5, letterSpacing: 0.2,
        }}>{name}</span>
      )}
    </div>
  );
}

// ── Buttons ──────────────────────────────────────────────────
function BigButton({ children, onClick, disabled, variant = 'filled', loading, style = {} }) {
  const filled = variant === 'filled';
  return (
    <button onClick={disabled || loading ? undefined : onClick} disabled={disabled} style={{
      width: '100%', height: 50, borderRadius: T.radiusBtn, border: 'none',
      background: filled ? (disabled ? 'rgba(120,120,128,0.18)' : T.accent) : T.accentDim,
      color: filled ? (disabled ? 'rgba(60,60,67,0.35)' : '#fff') : T.accent,
      fontFamily: T.font, fontSize: 17, fontWeight: 600, letterSpacing: -0.2,
      cursor: disabled ? 'default' : 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      transition: 'transform 0.12s ease, opacity 0.15s ease',
      WebkitTapHighlightColor: 'transparent',
      ...style,
    }}
    onPointerDown={e => { if (!disabled && !loading) e.currentTarget.style.transform = 'scale(0.975)'; }}
    onPointerUp={e => { e.currentTarget.style.transform = 'scale(1)'; }}
    onPointerLeave={e => { e.currentTarget.style.transform = 'scale(1)'; }}>
      {loading ? <Spinner color={filled ? '#fff' : T.accent} /> : children}
    </button>
  );
}

function TextButton({ children, onClick, color = T.accent, style = {} }) {
  return (
    <button onClick={onClick} style={{
      background: 'none', border: 'none', cursor: 'pointer',
      fontFamily: T.font, fontSize: 16, fontWeight: 500, color,
      padding: '10px 12px', letterSpacing: -0.2, WebkitTapHighlightColor: 'transparent',
      ...style,
    }}>{children}</button>
  );
}

function Spinner({ color = T.accent, size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 20 20" style={{ animation: 'shopSpin 0.8s linear infinite' }}>
      <circle cx="10" cy="10" r="8" stroke={color} strokeOpacity="0.25" strokeWidth="2.4" fill="none"/>
      <path d="M10 2a8 8 0 0 1 8 8" stroke={color} strokeWidth="2.4" fill="none" strokeLinecap="round"/>
    </svg>
  );
}

// ── Badges / chips ───────────────────────────────────────────
function StatusBadge({ status }) {
  const m = window.ShopData.ORDER_STATUS[status];
  if (!m) return null;
  return (
    <span style={{
      fontFamily: T.font, fontSize: 13, fontWeight: 600, color: m.color,
      background: m.bg, borderRadius: 100, padding: '4px 10px', whiteSpace: 'nowrap',
    }}>{tr(m.label)}</span>
  );
}

function StockBadge({ inStock, small }) {
  const c = inStock ? T.green : T.red;
  return (
    <span style={{
      fontFamily: T.font, fontSize: small ? 12 : 13, fontWeight: 600, color: c,
      background: inStock ? 'rgba(30,138,76,0.10)' : 'rgba(214,59,47,0.10)',
      borderRadius: 100, padding: small ? '3px 8px' : '4px 10px', whiteSpace: 'nowrap',
    }}>{inStock ? tr('Мавжуд') : tr('Тугаган')}</span>
  );
}

function Chip({ label, selected, onClick }) {
  return (
    <button onClick={onClick} style={{
      height: 34, padding: '0 14px', borderRadius: 100, flexShrink: 0,
      border: selected ? '1px solid transparent' : '1px solid rgba(60,60,67,0.18)',
      background: selected ? T.accent : 'transparent',
      color: selected ? '#fff' : T.text,
      fontFamily: T.font, fontSize: 14.5, fontWeight: 500, letterSpacing: -0.15,
      cursor: 'pointer', transition: 'background 0.2s ease, color 0.2s ease, border-color 0.2s ease',
      WebkitTapHighlightColor: 'transparent',
    }}>{label}</button>
  );
}

// ── Quantity stepper ─────────────────────────────────────────
function Stepper({ qty, onChange, compact }) {
  const h = compact ? 30 : 38;
  const btn = (label, delta) => (
    <button onClick={() => onChange(qty + delta)} style={{
      width: h + 4, height: h, border: 'none', background: 'none', cursor: 'pointer',
      fontFamily: T.font, fontSize: compact ? 17 : 20, fontWeight: 500, color: T.text,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      WebkitTapHighlightColor: 'transparent', padding: 0,
    }} aria-label={delta > 0 ? 'Кўпайтириш' : 'Камайтириш'}>{label}</button>
  );
  return (
    <div style={{
      display: 'flex', alignItems: 'center', background: T.fill,
      borderRadius: 100, height: h,
    }}>
      {btn('−', -1)}
      <span style={{
        fontFamily: T.font, fontSize: compact ? 15 : 17, fontWeight: 600,
        minWidth: 22, textAlign: 'center', color: T.text,
        fontVariantNumeric: 'tabular-nums',
      }}>{window.ShopData.formatQty(qty)}</span>
      {btn('+', 1)}
    </div>
  );
}

// ── Form field ───────────────────────────────────────────────
function Field({ label, error, children }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {label && <label style={{ fontFamily: T.font, fontSize: 14, fontWeight: 500, color: T.sec }}>{label}</label>}
      {children}
      {error && <div style={{ fontFamily: T.font, fontSize: 13, color: T.red }}>{error}</div>}
    </div>
  );
}

const shopInputStyle = (error) => ({
  height: 48, borderRadius: T.radiusInput, border: error ? `1px solid ${T.red}` : '1px solid transparent',
  background: T.fill, padding: '0 14px', fontFamily: T.font, fontSize: 17,
  color: T.text, outline: 'none', width: '100%', boxSizing: 'border-box',
  WebkitAppearance: 'none', letterSpacing: -0.2,
});

function SectionHeader({ children }) {
  return (
    <div style={{
      fontFamily: T.font, fontSize: 13, fontWeight: 600, color: T.sec,
      textTransform: 'uppercase', letterSpacing: 0.4, padding: '0 2px',
    }}>{children}</div>
  );
}

// ── Compact nav header (pushed screens) ─────────────────────
function NavHeader({ title, onBack, right }) {
  return (
    <div style={{
      paddingTop: 62, paddingBottom: 8, background: T.bg,
      display: 'flex', alignItems: 'center', padding: '62px 8px 8px',
      position: 'relative', zIndex: 5, flexShrink: 0,
    }}>
      <button onClick={onBack} style={{
        width: 44, height: 44, border: 'none', background: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        WebkitTapHighlightColor: 'transparent', padding: 0,
      }} aria-label="Орқага">{Ic.chevronL(T.accent)}</button>
      <div style={{
        flex: 1, textAlign: 'center', fontFamily: T.font, fontSize: 17,
        fontWeight: 600, color: T.text, letterSpacing: -0.3,
        overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
      }}>{title}</div>
      <div style={{ width: 44, display: 'flex', justifyContent: 'center' }}>{right}</div>
    </div>
  );
}

// ── Toast ────────────────────────────────────────────────────
function Toast({ message, show }) {
  return (
    <div style={{
      position: 'absolute', bottom: 120, left: 0, right: 0,
      display: 'flex', justifyContent: 'center', pointerEvents: 'none', zIndex: 80,
      opacity: show ? 1 : 0, transform: show ? 'translateY(0)' : 'translateY(8px)',
      transition: 'opacity 0.25s ease, transform 0.25s ease',
    }}>
      <div style={{
        background: 'rgba(28,28,30,0.92)', color: '#fff', borderRadius: 100,
        padding: '10px 18px', fontFamily: T.font, fontSize: 14.5, fontWeight: 500,
        backdropFilter: 'blur(10px)', maxWidth: 300, textAlign: 'center',
      }}>{message}</div>
    </div>
  );
}

Object.assign(window, {
  T, Ic, ProductImage, BigButton, TextButton, Spinner,
  StatusBadge, StockBadge, Chip, Stepper, Field, shopInputStyle,
  SectionHeader, NavHeader, Toast,
});
