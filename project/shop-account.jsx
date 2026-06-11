// Profile, Login (SMS OTP), Order Status

// ── Order card (shared by profile history + status result) ──
function OrderCard({ order, expanded = true }) {
  const { formatSum, formatQty } = window.ShopData;
  return (
    <div style={{
      border: `1px solid ${T.sep}`, borderRadius: T.radiusCard,
      padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 10,
      background: T.bg,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 8 }}>
        <span style={{
          fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', fontSize: 15,
          fontWeight: 600, color: T.text, letterSpacing: 0.3,
        }}>{order.orderNumber}</span>
        <StatusBadge status={order.status} />
      </div>
      {expanded && (
        <React.Fragment>
          <div style={{ borderTop: `0.5px solid ${T.sep}` }}></div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {order.lines.map((l, i) => (
              <div key={i} style={{ display: 'flex', justifyContent: 'space-between', gap: 12, fontFamily: T.font, fontSize: 14.5 }}>
                <span style={{ color: T.text, letterSpacing: -0.15, flex: 1, minWidth: 0 }}>
                  {l.productName}
                  <span style={{ color: T.sec }}> × {formatQty(l.quantity)}</span>
                </span>
                <span style={{ color: T.text, whiteSpace: 'nowrap' }}>{formatSum(l.lineTotal)}</span>
              </div>
            ))}
            {order.deliveryFee > 0 && (
              <div key={i} style={{ display: 'flex', justifyContent: 'space-between', fontFamily: T.font, fontSize: 14.5, color: T.sec }}>
                <span>{tr('Етказиб бериш')}</span>
                <span>{formatSum(order.deliveryFee)}</span>
              </div>
            )}
          </div>
          <div style={{ borderTop: `0.5px solid ${T.sep}` }}></div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span style={{ fontFamily: T.font, fontSize: 14.5, color: T.sec }}>{tr('Жами')}</span>
            <span style={{ fontFamily: T.font, fontSize: 17, fontWeight: 700, color: T.text, letterSpacing: -0.2 }}>
              {formatSum(order.totalAmount)}
            </span>
          </div>
        </React.Fragment>
      )}
    </div>
  );
}

// ── Profile ──────────────────────────────────────────────────
function ProfileScreen({ app }) {
  const { formatPhone } = window.ShopData;

  const menu = (
    <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div style={{ border: `1px solid ${T.sep}`, borderRadius: T.radiusCard, overflow: 'hidden' }}>
        <MenuRow icon={Ic.ticket(T.accent, 18)} label={tr('Купонлар')} onClick={() => app.push({ name: 'coupons' })} />
        <MenuRow icon={Ic.gift(T.accent, 18)} label={tr('Дўстларни таклиф қилиш')} onClick={() => app.push({ name: 'referrals' })} />
        <MenuRow icon={Ic.bell(T.accent, 18)} label={tr('Билдиришномалар')} onClick={() => app.push({ name: 'notifications' })} />
        <MenuRow icon={Ic.box(T.accent, 18)} label={tr('Буюртма ҳолатини текшириш')} onClick={() => app.push({ name: 'status' })} />
        {/* language switcher */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, minHeight: 52, padding: '6px 14px' }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8, background: T.accentDim,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>{Ic.globe(T.accent, 18)}</div>
          <span style={{ flex: 1, fontFamily: T.font, fontSize: 16.5, color: T.text, letterSpacing: -0.2 }}>{tr2('Тил', 'Язык')}</span>
          <div style={{ display: 'flex', background: T.fill, borderRadius: 8, padding: 2 }}>
            {[['uz', 'Ўзбекча'], ['ru', 'Русский']].map(([id, label]) => (
              <button key={id} onClick={() => app.setLang(id)} style={{
                height: 30, padding: '0 12px', borderRadius: 6, border: 'none', cursor: 'pointer',
                background: app.lang === id ? '#fff' : 'transparent',
                boxShadow: app.lang === id ? '0 1px 3px rgba(0,0,0,0.10)' : 'none',
                fontFamily: T.font, fontSize: 13, fontWeight: app.lang === id ? 600 : 500,
                color: app.lang === id ? T.text : T.sec, letterSpacing: -0.1,
                transition: 'background 0.18s ease, box-shadow 0.18s ease',
                WebkitTapHighlightColor: 'transparent',
              }}>{label}</button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  if (!app.user) {
    return (
      <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
        <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 120 }}>
          <div style={{ padding: '74px 16px 0' }}>
            <h1 style={{ margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700, letterSpacing: 0.2, color: T.text, lineHeight: '41px' }}>{tr('Профил')}</h1>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '28px 32px 26px' }}>
            {Ic.personBig(T.ter, 64)}
            <div style={{ marginTop: 12, fontFamily: T.font, fontSize: 15, color: T.sec, textAlign: 'center', letterSpacing: -0.2, textWrap: 'pretty' }}>
              {tr('Буюртмалар тарихини кўриш учун тизимга киринг')}
            </div>
            <BigButton style={{ marginTop: 18, width: 'auto', padding: '0 48px' }}
              onClick={() => app.push({ name: 'login' })}>{tr('Кириш')}</BigButton>
          </div>
          {menu}
        </div>
      </div>
    );
  }

  const orders = app.allOrders().filter(o => o.phone === app.user.phone);

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 120 }}>
        <div style={{ padding: '74px 16px 0' }}>
          <h1 style={{ margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700, letterSpacing: 0.2, color: T.text, lineHeight: '41px' }}>{tr('Профил')}</h1>
        </div>

        {/* user header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '18px 16px 18px' }}>
          <div style={{
            width: 52, height: 52, borderRadius: 100, background: T.accentDim,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>{Ic.person(T.accent, 26)}</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2, minWidth: 0 }}>
            {app.user.name && (
              <div style={{ fontFamily: T.font, fontSize: 18, fontWeight: 600, color: T.text, letterSpacing: -0.25 }}>{app.user.name}</div>
            )}
            <div style={{ fontFamily: T.font, fontSize: 14.5, color: T.sec, fontVariantNumeric: 'tabular-nums' }}>
              {formatPhone(app.user.phone)}
            </div>
          </div>
        </div>

        {menu}

        <div style={{ padding: '22px 16px 0', display: 'flex', flexDirection: 'column', gap: 12 }}>
          <SectionHeader>{tr('Буюртмалар')}</SectionHeader>
          {orders.length === 0 ? (
            <div style={{ fontFamily: T.font, fontSize: 15, color: T.sec, padding: '24px 0', textAlign: 'center' }}>
              {tr('Ҳозирча буюртмалар йўқ')}
            </div>
          ) : (
            orders.map(o => <OrderCard key={o.orderNumber} order={o} />)
          )}
        </div>

        <div style={{ display: 'flex', justifyContent: 'center', padding: '22px 0 0' }}>
          <TextButton color={T.red} onClick={app.logout}>{tr('Чиқиш')}</TextButton>
        </div>
      </div>
    </div>
  );
}

// ── Login (SMS OTP, 2 stages) ────────────────────────────────
function LoginScreen({ app }) {
  const { useState, useEffect, useRef } = React;
  const { formatPhone } = window.ShopData;
  const [stage, setStage] = useState(1);
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [name, setName] = useState('');
  const [error, setError] = useState('');
  const [sending, setSending] = useState(false);
  const [cooldown, setCooldown] = useState(0);
  const codeRef = useRef(null);

  useEffect(() => {
    if (cooldown <= 0) return;
    const t = setTimeout(() => setCooldown(c => c - 1), 1000);
    return () => clearTimeout(t);
  }, [cooldown]);

  const sendCode = () => {
    if (phone.replace(/\D/g, '').length !== 9) { setError(tr('Телефон рақам нотўғри')); return; }
    setError('');
    setSending(true);
    setTimeout(() => {
      setSending(false);
      setStage(2);
      setCooldown(30);
      setTimeout(() => codeRef.current && codeRef.current.focus(), 60);
    }, 900);
  };

  const verify = () => {
    if (code.length !== 6) { setError(tr('Код нотўғри ёки муддати ўтган')); return; }
    setError('');
    setSending(true);
    setTimeout(() => {
      app.login({ phone: phone.replace(/\D/g, ''), name: name.trim() });
      app.pop();
    }, 800);
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <NavHeader title={tr2('Кириш', 'Вход')} onBack={app.pop} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '18px 24px 40px' }}>
        {stage === 1 ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
            <p style={{ margin: 0, fontFamily: T.font, fontSize: 16, color: T.sec, lineHeight: 1.45, letterSpacing: -0.2, textWrap: 'pretty' }}>
              {tr('Телефон рақамингизга SMS код юборамиз')}
            </p>
            <Field error={error}>
              <input value={formatPhone(phone)} inputMode="numeric" autoFocus
                onChange={e => setPhone(e.target.value.replace(/^\+?998/, '').replace(/\D/g, '').slice(0, 9))}
                style={{ ...shopInputStyle(error), fontSize: 19, height: 52, fontVariantNumeric: 'tabular-nums' }} />
            </Field>
            <BigButton onClick={sendCode} loading={sending}>{tr('Код юбориш')}</BigButton>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 2, alignItems: 'center' }}>
              <span style={{ fontFamily: T.font, fontSize: 17, fontWeight: 600, color: T.text, fontVariantNumeric: 'tabular-nums' }}>
                {formatPhone(phone)}
              </span>
              <TextButton style={{ fontSize: 14, padding: '4px 8px' }}
                onClick={() => { setStage(1); setCode(''); setError(''); }}>{tr('Рақамни ўзгартириш')}</TextButton>
            </div>

            {/* 6-digit boxes over hidden input */}
            <div style={{ position: 'relative', display: 'flex', justifyContent: 'center' }}
              onClick={() => codeRef.current && codeRef.current.focus()}>
              <div style={{ display: 'flex', gap: 8 }}>
                {Array.from({ length: 6 }).map((_, i) => (
                  <div key={i} style={{
                    width: 44, height: 54, borderRadius: 10,
                    background: T.fill,
                    border: i === code.length ? `1.5px solid ${T.accent}` : '1.5px solid transparent',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontFamily: T.font, fontSize: 24, fontWeight: 600, color: T.text,
                    fontVariantNumeric: 'tabular-nums', transition: 'border-color 0.15s ease',
                  }}>{code[i] || ''}</div>
                ))}
              </div>
              <input ref={codeRef} value={code} inputMode="numeric" autoComplete="one-time-code"
                onChange={e => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                style={{
                  position: 'absolute', inset: 0, opacity: 0, width: '100%',
                  border: 'none', outline: 'none', fontSize: 24,
                }} />
            </div>
            {error && <div style={{ fontFamily: T.font, fontSize: 13.5, color: T.red, textAlign: 'center' }}>{error}</div>}
            <div style={{ fontFamily: T.font, fontSize: 13, color: T.ter, textAlign: 'center' }}>
              {tr('Демо: исталган 6 хонали код')}
            </div>

            <Field>
              <input value={name} onChange={e => setName(e.target.value)} placeholder={tr('Исмингиз (ихтиёрий)')}
                style={shopInputStyle(false)} />
            </Field>

            <BigButton onClick={verify} loading={sending} disabled={code.length !== 6}>{tr('Тасдиқлаш')}</BigButton>
            <div style={{ display: 'flex', justifyContent: 'center' }}>
              {cooldown > 0 ? (
                <span style={{ fontFamily: T.font, fontSize: 14.5, color: T.ter, padding: '10px 12px' }}>
                  {tr('Қайта юбориш')} — {cooldown} {tr2('сония', 'сек')}
                </span>
              ) : (
                <TextButton style={{ fontSize: 14.5 }} onClick={() => { setCooldown(30); app.toast(tr('Код қайта юборилди')); }}>
                  {tr('Қайта юбориш')}
                </TextButton>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Order status lookup ──────────────────────────────────────
function OrderStatusScreen({ app, screen }) {
  const { useState } = React;
  const { formatPhone } = window.ShopData;
  const [num, setNum] = useState(screen.orderNumber || '');
  const [phone, setPhone] = useState(app.lastOrderPhone || (app.user ? app.user.phone : ''));
  const [result, setResult] = useState(null);
  const [notFound, setNotFound] = useState(false);
  const [searching, setSearching] = useState(false);

  const lookup = () => {
    setSearching(true);
    setResult(null);
    setNotFound(false);
    setTimeout(() => {
      setSearching(false);
      const d = phone.replace(/\D/g, '');
      const found = app.allOrders().find(o =>
        o.orderNumber.toLowerCase() === num.trim().toLowerCase() && o.phone === d);
      if (found) setResult(found); else setNotFound(true);
    }, 700);
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <NavHeader title={tr('Буюртма ҳолати')} onBack={app.pop} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '10px 16px 40px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <Field>
            <input value={num} onChange={e => setNum(e.target.value)} placeholder={tr('Буюртма рақами (WO-000012)')}
              style={{ ...shopInputStyle(false), fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', fontSize: 15.5 }} />
          </Field>
          <Field>
            <input value={formatPhone(phone)} inputMode="numeric"
              onChange={e => setPhone(e.target.value.replace(/^\+?998/, '').replace(/\D/g, '').slice(0, 9))}
              placeholder="+998" style={{ ...shopInputStyle(false), fontVariantNumeric: 'tabular-nums' }} />
          </Field>
          <BigButton onClick={lookup} loading={searching} disabled={!num.trim() || phone.replace(/\D/g, '').length !== 9}>
            {tr('Излаш')}
          </BigButton>

          {notFound && (
            <div style={{
              fontFamily: T.font, fontSize: 14.5, color: T.red, textAlign: 'center',
              padding: '8px 12px', lineHeight: 1.45, textWrap: 'pretty',
            }}>{tr('Буюртма топилмади. Рақам ва телефонни текширинг.')}</div>
          )}

          {result && (
            <div style={{ marginTop: 6 }}>
              <OrderCard order={result} />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ProfileScreen, LoginScreen, OrderStatusScreen, OrderCard });
