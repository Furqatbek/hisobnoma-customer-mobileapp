// Cart, Checkout, Order Success

// ── Swipe-to-delete row ──────────────────────────────────────
function SwipeRow({ onDelete, children }) {
  const { useState, useRef } = React;
  const [x, setX] = useState(0);
  const drag = useRef(null);
  const W = 84;

  const down = (e) => {
    drag.current = { startX: e.clientX, baseX: x };
    e.currentTarget.setPointerCapture(e.pointerId);
  };
  const move = (e) => {
    if (!drag.current) return;
    const dx = e.clientX - drag.current.startX;
    setX(Math.min(0, Math.max(-W - 16, drag.current.baseX + dx)));
  };
  const up = () => {
    if (!drag.current) return;
    drag.current = null;
    setX(prev => (prev < -W / 2 ? -W : 0));
  };

  return (
    <div style={{ position: 'relative', overflow: 'hidden' }}>
      <button onClick={onDelete} style={{
        position: 'absolute', top: 0, bottom: 0, right: 0, width: W,
        background: T.red, color: '#fff', border: 'none', cursor: 'pointer',
        fontFamily: T.font, fontSize: 14.5, fontWeight: 600,
        opacity: x < -10 ? 1 : 0, transition: 'opacity 0.15s ease',
        WebkitTapHighlightColor: 'transparent',
      }}>{tr('Ўчириш')}</button>
      <div
        onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={up}
        style={{
          transform: `translateX(${x}px)`,
          transition: drag.current ? 'none' : 'transform 0.25s cubic-bezier(0.25,1,0.4,1)',
          background: T.bg, touchAction: 'pan-y', cursor: 'grab',
        }}>
        {children}
      </div>
    </div>
  );
}

// ── Cart screen ──────────────────────────────────────────────
function CartScreen({ app }) {
  const { formatSum, productById } = window.ShopData;
  const ids = Object.keys(app.cart).map(Number);
  const subtotal = ids.reduce((s, id) => s + productById(id).price * app.cart[id], 0);

  if (ids.length === 0) {
    return (
      <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '74px 16px 0' }}>
          <h1 style={{ margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700, letterSpacing: 0.2, color: T.text, lineHeight: '41px' }}>{tr('Сават')}</h1>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 18, padding: '0 32px 140px' }}>
          {Ic.bag()}
          <div style={{ fontFamily: T.font, fontSize: 17, color: T.sec, letterSpacing: -0.2 }}>{tr('Сават бўш')}</div>
          <BigButton variant="ghost" style={{ width: 'auto', padding: '0 24px', height: 44 }}
            onClick={() => app.setTab('catalog')}>{tr('Каталогга қайтиш')}</BigButton>
        </div>
      </div>
    );
  }

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 230 }}>
        <div style={{ padding: '74px 16px 6px' }}>
          <h1 style={{ margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700, letterSpacing: 0.2, color: T.text, lineHeight: '41px' }}>{tr('Сават')}</h1>
        </div>

        <div>
          {ids.map((id, i) => {
            const p = productById(id);
            const qty = app.cart[id];
            return (
              <SwipeRow key={id} onDelete={() => app.setQty(id, 0)}>
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
                  borderBottom: i < ids.length - 1 ? `0.5px solid ${T.sep}` : 'none',
                }}>
                  <ProductImage product={p} label={null} radius={10} style={{ width: 56, height: 56, flexShrink: 0 }} />
                  <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 3 }}>
                    <div style={{
                      fontFamily: T.font, fontSize: 15.5, fontWeight: 500, color: T.text,
                      letterSpacing: -0.2, lineHeight: 1.3,
                      display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
                    }}>{p.name}</div>
                    <div style={{ fontFamily: T.font, fontSize: 13.5, color: T.sec }}>
                      {formatSum(p.price)}{p.unitName ? ` / ${tr(p.unitName)}` : ''}
                    </div>
                    <div style={{ marginTop: 4, display: 'flex' }}>
                      <Stepper compact qty={qty} onChange={(n) => app.setQty(id, n)} />
                    </div>
                  </div>
                  <div style={{
                    fontFamily: T.font, fontSize: 16, fontWeight: 700, color: T.text,
                    letterSpacing: -0.2, whiteSpace: 'nowrap', alignSelf: 'flex-start', paddingTop: 4,
                  }}>{formatSum(p.price * qty)}</div>
                </div>
              </SwipeRow>
            );
          })}
        </div>
        <div style={{
          padding: '14px 16px 0', fontFamily: T.font, fontSize: 13, color: T.ter, textAlign: 'center',
        }}>{tr('Ўчириш учун чапга суринг')}</div>
      </div>

      {/* summary pinned above tab bar */}
      <div style={{
        position: 'absolute', bottom: 86, left: 0, right: 0,
        padding: '14px 16px 16px',
        background: 'rgba(255,255,255,0.92)', backdropFilter: 'blur(16px) saturate(180%)',
        WebkitBackdropFilter: 'blur(16px) saturate(180%)',
        borderTop: `0.5px solid ${T.sep}`,
        display: 'flex', flexDirection: 'column', gap: 12,
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span style={{ fontFamily: T.font, fontSize: 16, color: T.sec }}>{tr('Жами')}</span>
          <span style={{ fontFamily: T.font, fontSize: 20, fontWeight: 700, color: T.text, letterSpacing: -0.3 }}>
            {formatSum(subtotal)}
          </span>
        </div>
        <BigButton onClick={() => app.push({ name: 'checkout' })}>{tr('Буюртма бериш')}</BigButton>
      </div>
    </div>
  );
}

// ── Checkout ─────────────────────────────────────────────────
function CheckoutScreen({ app }) {
  const { useState } = React;
  const { formatSum, formatPhone, productById, REGIONS, VILLAGES } = window.ShopData;
  const [name, setName] = useState(app.user ? app.user.name : '');
  const [phone, setPhone] = useState(app.user ? app.user.phone : '');
  const [regionId, setRegionId] = useState('');
  const [villageId, setVillageId] = useState('');
  const [note, setNote] = useState('');
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);

  const ids = Object.keys(app.cart).map(Number);
  const subtotal = ids.reduce((s, id) => s + productById(id).price * app.cart[id], 0);
  const region = REGIONS.find(r => r.id === Number(regionId));
  const fee = region ? region.deliveryFee : 0;
  const villages = VILLAGES.filter(v => v.regionId === Number(regionId));

  const selectStyle = { ...shopInputStyle(false), appearance: 'none', color: T.text, cursor: 'pointer' };

  const submit = () => {
    const errs = {};
    if (!name.trim()) errs.name = tr('Исмингизни киритинг');
    if (phone.replace(/\D/g, '').length !== 9) errs.phone = tr('Телефон рақам нотўғри');
    setErrors(errs);
    if (Object.keys(errs).length) return;
    setSubmitting(true);
    setTimeout(() => {
      const order = app.placeOrder({ name: name.trim(), phone: phone.replace(/\D/g, ''), regionId, villageId, note, fee, subtotal });
      app.replace({ name: 'success', orderNumber: order.orderNumber, total: order.totalAmount });
    }, 1300);
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <NavHeader title={tr('Буюртма')} onBack={app.pop} />
      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 16px 40px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <SectionHeader>{tr('Контакт')}</SectionHeader>
            <Field error={errors.name}>
              <input value={name} onChange={e => setName(e.target.value)} placeholder={tr('Исмингиз')}
                style={shopInputStyle(errors.name)} />
            </Field>
            <Field error={errors.phone}>
              <input value={formatPhone(phone)} inputMode="numeric"
                onChange={e => setPhone(e.target.value.replace(/^\+?998/, '').replace(/\D/g, '').slice(0, 9))}
                placeholder="+998" style={{ ...shopInputStyle(errors.phone), fontVariantNumeric: 'tabular-nums' }} />
            </Field>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <SectionHeader>{tr('Етказиб бериш')}</SectionHeader>
            <div style={{ position: 'relative' }}>
              <select value={regionId} onChange={e => { setRegionId(e.target.value); setVillageId(''); }} style={selectStyle}>
                <option value="">{tr('Туман')}</option>
                {REGIONS.map(r => <option key={r.id} value={r.id}>{tr(r.name)}</option>)}
              </select>
              <span style={{ position: 'absolute', right: 14, top: 18, pointerEvents: 'none' }}>
                <svg width="12" height="8" viewBox="0 0 12 8"><path d="M1 1.5L6 6.5L11 1.5" stroke="rgba(60,60,67,0.4)" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
              </span>
            </div>
            {regionId && (
              <div style={{ position: 'relative' }}>
                <select value={villageId} onChange={e => setVillageId(e.target.value)} style={selectStyle}>
                  <option value="">{tr('Қишлоқ / маҳалла')}</option>
                  {villages.map(v => <option key={v.id} value={v.id}>{tr(v.name)}</option>)}
                </select>
                <span style={{ position: 'absolute', right: 14, top: 18, pointerEvents: 'none' }}>
                  <svg width="12" height="8" viewBox="0 0 12 8"><path d="M1 1.5L6 6.5L11 1.5" stroke="rgba(60,60,67,0.4)" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
                </span>
              </div>
            )}
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <SectionHeader>{tr('Қўшимча')}</SectionHeader>
            <textarea value={note} onChange={e => setNote(e.target.value.slice(0, 500))}
              placeholder={tr('Изоҳ (ихтиёрий)')} rows={3}
              style={{ ...shopInputStyle(false), height: 'auto', padding: '12px 14px', resize: 'none', lineHeight: 1.4 }} />
          </div>

          {/* summary card */}
          <div style={{
            background: 'rgba(120,120,128,0.07)', borderRadius: T.radiusCard,
            padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 9,
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: T.font, fontSize: 15, color: T.sec }}>
              <span>{tr2(`${ids.length} та маҳсулот`, `Товаров: ${ids.length}`)}</span>
              <span style={{ color: T.text }}>{formatSum(subtotal)}</span>
            </div>
            {fee > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: T.font, fontSize: 15, color: T.sec }}>
                <span>{tr('Етказиб бериш')}</span>
                <span style={{ color: T.text }}>{formatSum(fee)}</span>
              </div>
            )}
            <div style={{ borderTop: `0.5px solid ${T.sep}` }}></div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <span style={{ fontFamily: T.font, fontSize: 16, fontWeight: 600, color: T.text }}>{tr('Жами тўлов')}</span>
              <span style={{ fontFamily: T.font, fontSize: 20, fontWeight: 700, color: T.text, letterSpacing: -0.3 }}>
                {formatSum(subtotal + fee)}
              </span>
            </div>
          </div>

          <BigButton onClick={submit} loading={submitting}>{tr('Буюртмани юбориш')}</BigButton>
        </div>
      </div>
    </div>
  );
}

// ── Order success ────────────────────────────────────────────
function OrderSuccessScreen({ app, screen }) {
  const { useState, useEffect } = React;
  const { formatSum } = window.ShopData;
  // entrance animations settle to 'none' so the steady state is fully visible
  const [settled, setSettled] = useState(false);
  useEffect(() => { const t = setTimeout(() => setSettled(true), 700); return () => clearTimeout(t); }, []);
  const anim = (name) => settled ? 'none' : name;

  const copy = () => {
    try { navigator.clipboard.writeText(screen.orderNumber); } catch (e) {}
    app.toast(tr('Нусха олинди'));
  };

  return (
    <div style={{
      position: 'absolute', inset: 0, background: T.bg,
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      padding: '0 28px', gap: 0,
    }}>
      <div style={{
        width: 88, height: 88, borderRadius: 100, background: 'rgba(30,138,76,0.10)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        animation: anim('shopPop 0.5s cubic-bezier(0.34,1.56,0.64,1)'),
      }}>
        <div style={{
          width: 60, height: 60, borderRadius: 100, background: T.green,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Ic.check('#fff', 30)}</div>
      </div>

      <h2 style={{
        margin: '24px 0 0', fontFamily: T.font, fontSize: 22, fontWeight: 700,
        color: T.text, textAlign: 'center', letterSpacing: -0.3,
        animation: anim('shopFadeUp 0.45s ease'),
      }}>{tr('Буюртмангиз қабул қилинди!')}</h2>

      <button onClick={copy} style={{
        marginTop: 18, display: 'flex', alignItems: 'center', gap: 8,
        background: T.fill, border: 'none', borderRadius: 100, padding: '10px 18px',
        cursor: 'pointer', WebkitTapHighlightColor: 'transparent',
        animation: anim('shopFadeUp 0.45s ease'),
      }}>
        <span style={{
          fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', fontSize: 17,
          fontWeight: 600, color: T.text, letterSpacing: 0.5,
        }}>{screen.orderNumber}</span>
        {Ic.copy()}
      </button>

      <div style={{
        marginTop: 14, fontFamily: T.font, fontSize: 17, fontWeight: 600, color: T.text,
        animation: anim('shopFadeUp 0.45s ease'),
      }}>{formatSum(screen.total)}</div>

      <div style={{
        marginTop: 8, fontFamily: T.font, fontSize: 14.5, color: T.sec, textAlign: 'center',
        animation: anim('shopFadeUp 0.45s ease'),
      }}>{tr('Тез орада сиз билан боғланамиз...')}</div>

      <div style={{ marginTop: 36, width: '100%', display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'center', animation: anim('shopFadeUp 0.45s ease') }}>
        <BigButton onClick={() => { app.resetCartStack(); app.setTab('catalog'); }}>{tr('Каталогга қайтиш')}</BigButton>
        <TextButton onClick={() => app.push({ name: 'status', orderNumber: screen.orderNumber })}>
          {tr('Буюртма ҳолатини текшириш')}
        </TextButton>
      </div>
    </div>
  );
}

Object.assign(window, { CartScreen, CheckoutScreen, OrderSuccessScreen, SwipeRow });
