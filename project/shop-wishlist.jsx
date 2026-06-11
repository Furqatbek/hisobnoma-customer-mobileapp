// Wishlist (Севимлилар) — root tab with back-in-stock / discount alerts

function WishAlertChip({ type, product }) {
  if (type === 'back') {
    return (
      <span style={{
        fontFamily: T.font, fontSize: 12, fontWeight: 600, color: T.green,
        background: 'rgba(30,138,76,0.10)', borderRadius: 100, padding: '3px 9px', whiteSpace: 'nowrap',
      }}>{tr('Яна сотувда')}</span>
    );
  }
  const pct = Math.round((1 - product.price / product.oldPrice) * 100);
  return (
    <span style={{
      fontFamily: T.font, fontSize: 12, fontWeight: 600, color: '#E8730C',
      background: 'rgba(232,115,12,0.12)', borderRadius: 100, padding: '3px 9px', whiteSpace: 'nowrap',
    }}>−{pct}% {tr('чегирма')}</span>
  );
}

function WishlistScreen({ app }) {
  const { productById, formatSum } = window.ShopData;
  const ids = Object.keys(app.wishlist).map(Number).filter(id => productById(id));

  if (ids.length === 0) {
    return (
      <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '74px 16px 0' }}>
          <h1 style={{ margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700, letterSpacing: 0.2, color: T.text, lineHeight: '41px' }}>{tr('Севимлилар')}</h1>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 18, padding: '0 32px 140px' }}>
          {Ic.heart(T.ter, 52)}
          <div style={{ fontFamily: T.font, fontSize: 17, color: T.sec, letterSpacing: -0.2 }}>{tr('Севимлилар бўш')}</div>
          <BigButton variant="ghost" style={{ width: 'auto', padding: '0 24px', height: 44 }}
            onClick={() => app.setTab('catalog')}>{tr('Каталогга қайтиш')}</BigButton>
        </div>
      </div>
    );
  }

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 120 }}>
        <div style={{ padding: '74px 16px 6px' }}>
          <h1 style={{ margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700, letterSpacing: 0.2, color: T.text, lineHeight: '41px' }}>{tr('Севимлилар')}</h1>
        </div>

        <div>
          {ids.map((id, i) => {
            const p = productById(id);
            const alert = app.wishAlert(id);
            const inCart = (app.cart[id] || 0) > 0;
            const canBuy = p.inStock;
            return (
              <SwipeRow key={id} onDelete={() => app.toggleWish(id)}>
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
                  borderBottom: i < ids.length - 1 ? `0.5px solid ${T.sep}` : 'none',
                }}>
                  <div onClick={() => app.push({ name: 'product', productId: id })} style={{ cursor: 'pointer', flexShrink: 0 }}>
                    <ProductImage product={p} label={null} radius={10} style={{ width: 56, height: 56 }} />
                  </div>
                  <div onClick={() => app.push({ name: 'product', productId: id })}
                    style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 4, cursor: 'pointer' }}>
                    <div style={{
                      fontFamily: T.font, fontSize: 15.5, fontWeight: 500, color: T.text,
                      letterSpacing: -0.2, lineHeight: 1.3,
                      display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
                    }}>{p.name}</div>
                    <div style={{ display: 'flex', alignItems: 'baseline', gap: 7 }}>
                      <span style={{ fontFamily: T.font, fontSize: 15, fontWeight: 700, color: T.text, letterSpacing: -0.2 }}>
                        {formatSum(p.price)}
                      </span>
                      {p.oldPrice && (
                        <span style={{ fontFamily: T.font, fontSize: 13, color: T.ter, textDecoration: 'line-through' }}>
                          {formatSum(p.oldPrice)}
                        </span>
                      )}
                    </div>
                    {(alert || !p.inStock) && (
                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                        {alert && <WishAlertChip type={alert} product={p} />}
                        {!p.inStock && <StockBadge inStock={false} small={true} />}
                      </div>
                    )}
                  </div>
                  <button
                    onClick={() => {
                      if (!canBuy) return;
                      if (!inCart) { app.addToCart(id); app.toast(tr('Саватга қўшилди')); }
                      else { app.setTab('cart'); }
                    }}
                    aria-label={tr('Саватга қўшиш')}
                    style={{
                      width: 40, height: 40, borderRadius: 100, border: 'none', flexShrink: 0,
                      background: !canBuy ? 'rgba(120,120,128,0.12)' : (inCart ? T.accentDim : T.accent),
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      cursor: canBuy ? 'pointer' : 'default', WebkitTapHighlightColor: 'transparent', padding: 0,
                    }}>
                    {inCart ? Ic.check(T.accent, 17) : Ic.cart(!canBuy ? 'rgba(60,60,67,0.30)' : '#fff', 19)}
                  </button>
                </div>
              </SwipeRow>
            );
          })}
        </div>
        <div style={{
          padding: '14px 16px 0', fontFamily: T.font, fontSize: 13, color: T.ter, textAlign: 'center',
        }}>{tr('Ўчириш учун чапга суринг')}</div>
      </div>
    </div>
  );
}

Object.assign(window, { WishlistScreen, WishAlertChip });
