// Catalog screen + Product detail

// ── Skeleton card (shimmer) ─────────────────────────────────
function SkeletonCard() {
  const sk = {
    background: 'linear-gradient(100deg, rgba(120,120,128,0.10) 30%, rgba(120,120,128,0.05) 50%, rgba(120,120,128,0.10) 70%)',
    backgroundSize: '400% 100%', animation: 'shopShimmer 1.4s ease infinite',
  };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ ...sk, aspectRatio: '1 / 1', borderRadius: 12 }}></div>
      <div style={{ ...sk, height: 14, borderRadius: 6, width: '85%' }}></div>
      <div style={{ ...sk, height: 16, borderRadius: 6, width: '50%' }}></div>
    </div>
  );
}

// ── Product card ─────────────────────────────────────────────
function ProductCard({ product, onTap, wished, onToggleWish }) {
  return (
    <div onClick={onTap} role="button" style={{ display: 'flex', flexDirection: 'column', gap: 7, cursor: 'pointer', WebkitTapHighlightColor: 'transparent' }}>
      <div style={{ position: 'relative' }}>
        <ProductImage product={product} style={{ aspectRatio: '1 / 1', width: '100%' }} />
        {!product.inStock && (
          <span style={{
            position: 'absolute', top: 8, left: 8,
            background: 'rgba(214,59,47,0.85)', color: '#fff', borderRadius: 100,
            fontFamily: T.font, fontSize: 11.5, fontWeight: 600, padding: '3px 9px',
            backdropFilter: 'blur(4px)',
          }}>{tr('Тугаган')}</span>
        )}
        {onToggleWish && (
          <button onClick={(e) => { e.stopPropagation(); onToggleWish(); }}
            aria-label={tr('Севимлилар')}
            style={{
              position: 'absolute', top: 8, right: 8, width: 32, height: 32,
              borderRadius: 100, border: 'none', padding: 0,
              background: 'rgba(255,255,255,0.85)', backdropFilter: 'blur(6px)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer', boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
              WebkitTapHighlightColor: 'transparent',
            }}>
            {wished ? Ic.heartFill(T.red, 17) : Ic.heart('rgba(60,60,67,0.55)', 17)}
          </button>
        )}
      </div>
      <div style={{
        fontFamily: T.font, fontSize: 14.5, fontWeight: 500, color: T.text,
        lineHeight: 1.3, letterSpacing: -0.15,
        display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
        minHeight: 19,
      }}>{product.name}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: -2 }}>
        <span style={{ fontFamily: T.font, fontSize: 16, fontWeight: 700, color: T.text, letterSpacing: -0.2 }}>
          {window.ShopData.formatSum(product.price)}
        </span>
        {product.oldPrice && (
          <span style={{ fontFamily: T.font, fontSize: 12.5, color: T.ter, textDecoration: 'line-through' }}>
            {window.ShopData.formatSum(product.oldPrice)}
          </span>
        )}
      </div>
    </div>
  );
}

// ── Catalog screen ───────────────────────────────────────────
function CatalogScreen({ app }) {
  const { useState, useEffect, useRef } = React;
  const { CATEGORIES, PRODUCTS } = window.ShopData;
  const [search, setSearch] = useState('');
  const [catId, setCatId] = useState(null);
  const [loading, setLoading] = useState(!window.__shopCatalogLoaded);
  const [collapsed, setCollapsed] = useState(false);
  const scrollRef = useRef(null);

  useEffect(() => {
    if (loading) {
      const t = setTimeout(() => { setLoading(false); window.__shopCatalogLoaded = true; }, 1100);
      return () => clearTimeout(t);
    }
  }, []);

  const q = search.trim().toLowerCase();
  const items = PRODUCTS.filter(p =>
    (catId === null || p.categoryId === catId) &&
    (q === '' || p.name.toLowerCase().includes(q) || (p.brandName || '').toLowerCase().includes(q))
  );

  const onScroll = (e) => setCollapsed(e.target.scrollTop > 44);

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      {/* compact header appears on scroll */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, zIndex: 10,
        height: 102, display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
        paddingBottom: 10, pointerEvents: 'none',
        background: 'rgba(255,255,255,0.82)', backdropFilter: 'blur(16px) saturate(180%)',
        WebkitBackdropFilter: 'blur(16px) saturate(180%)',
        borderBottom: `0.5px solid ${T.sep}`,
        opacity: collapsed ? 1 : 0, transition: 'opacity 0.2s ease',
      }}>
        <span style={{ fontFamily: T.font, fontSize: 17, fontWeight: 600, color: T.text }}>Каталог</span>
      </div>

      <div ref={scrollRef} onScroll={onScroll} style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden' }}>
        {/* large title + notifications bell */}
        <div style={{ padding: '74px 16px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
          <h1 style={{
            margin: 0, fontFamily: T.font, fontSize: 34, fontWeight: 700,
            letterSpacing: 0.2, color: T.text, lineHeight: '41px',
          }}>Каталог</h1>
          <button onClick={() => app.push({ name: 'notifications' })} aria-label="Билдиришномалар" style={{
            width: 44, height: 44, border: 'none', background: T.fill, borderRadius: 100,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', position: 'relative', WebkitTapHighlightColor: 'transparent', padding: 0,
          }}>
            {Ic.bell(T.text, 21)}
            <span style={{
              position: 'absolute', top: 10, right: 11, width: 8, height: 8,
              borderRadius: 100, background: T.red, border: '1.5px solid #fff',
            }}></span>
          </button>
        </div>

        {/* search */}
        <div style={{ padding: '12px 16px 0' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            background: T.fill, borderRadius: 12, height: 40, padding: '0 12px',
          }}>
            {Ic.search()}
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder={tr('Қидириш...')}
              style={{
                flex: 1, border: 'none', background: 'none', outline: 'none',
                fontFamily: T.font, fontSize: 16.5, color: T.text, letterSpacing: -0.2,
                minWidth: 0,
              }}
            />
            {search && (
              <button onClick={() => setSearch('')} aria-label="Тозалаш" style={{
                border: 'none', background: T.fill2, borderRadius: 100, width: 20, height: 20,
                display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
                fontSize: 11, color: T.sec, padding: 0, fontFamily: T.font,
              }}>✕</button>
            )}
          </div>
        </div>

        {/* category chips */}
        <div style={{
          display: 'flex', gap: 8, overflowX: 'auto', padding: '14px 16px 4px',
          scrollbarWidth: 'none',
        }} className="shop-noscrollbar">
          <Chip label={tr('Барчаси')} selected={catId === null} onClick={() => setCatId(null)} />
          {CATEGORIES.map(c => (
            <Chip key={c.id} label={tr(c.name)} selected={catId === c.id} onClick={() => setCatId(c.id)} />
          ))}
        </div>

        {/* grid */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '18px 12px',
          padding: '14px 16px 120px',
        }}>
          {loading
            ? [0, 1, 2, 3, 4, 5].map(i => <SkeletonCard key={i} />)
            : items.map(p => (
                <ProductCard key={p.id} product={p}
                wished={!!app.wishlist[p.id]}
                onToggleWish={() => app.toggleWish(p.id)}
                onTap={() => app.push({ name: 'product', productId: p.id })} />
              ))}
        </div>

        {/* empty state */}
        {!loading && items.length === 0 && (
          <div style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
            padding: '36px 32px 140px', textAlign: 'center',
          }}>
            {Ic.box()}
            <div style={{ fontFamily: T.font, fontSize: 16.5, color: T.sec, letterSpacing: -0.2 }}>
              {tr('Ҳеч нарса топилмади')}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Product detail ───────────────────────────────────────────
function ProductDetailScreen({ app, screen }) {
  const { useState } = React;
  const { formatSum, productById, SHOP_INFO } = window.ShopData;
  const product = productById(screen.productId);
  const [page, setPage] = useState(0);
  const qty = app.cart[product.id] || 0;

  const imageCount = product.images || 1;

  const onHeroScroll = (e) => {
    const w = e.target.clientWidth;
    setPage(Math.round(e.target.scrollLeft / w));
  };

  return (
    <div style={{ position: 'absolute', inset: 0, background: T.bg, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', paddingBottom: 170 }}>
        {/* hero */}
        <div style={{ position: 'relative', height: 350, background: '#F4F4F3' }}>
          <div onScroll={onHeroScroll} style={{
            display: 'flex', overflowX: 'auto', scrollSnapType: 'x mandatory',
            height: '100%', scrollbarWidth: 'none',
          }} className="shop-noscrollbar">
            {Array.from({ length: imageCount }).map((_, i) => (
              <ProductImage key={i} product={product}
                label={imageCount > 1 ? `${product.name} · ${i + 1}` : product.name}
                radius={0} fontSize={13}
                style={{ width: '100%', height: '100%', flexShrink: 0, scrollSnapAlign: 'center', border: 'none' }} />
            ))}
          </div>
          {/* dots */}
          {imageCount > 1 && (
            <div style={{
              position: 'absolute', bottom: 26, left: 0, right: 0,
              display: 'flex', justifyContent: 'center', gap: 6,
            }}>
              {Array.from({ length: imageCount }).map((_, i) => (
                <div key={i} style={{
                  width: 7, height: 7, borderRadius: 100,
                  background: i === page ? T.text : 'rgba(0,0,0,0.2)',
                  transition: 'background 0.2s ease',
                }}></div>
              ))}
            </div>
          )}
          {/* floating back */}
          <button onClick={app.pop} aria-label="Орқага" style={{
            position: 'absolute', top: 62, left: 12, width: 40, height: 40,
            borderRadius: 100, border: '0.5px solid rgba(0,0,0,0.06)',
            background: 'rgba(255,255,255,0.75)', backdropFilter: 'blur(12px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', WebkitTapHighlightColor: 'transparent', padding: 0,
            boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
          }}>{Ic.chevronL(T.text, 18)}</button>
          {/* floating wishlist toggle */}
          <button onClick={() => app.toggleWish(product.id)} aria-label={tr('Севимлилар')} style={{
            position: 'absolute', top: 62, right: 12, width: 40, height: 40,
            borderRadius: 100, border: '0.5px solid rgba(0,0,0,0.06)',
            background: 'rgba(255,255,255,0.75)', backdropFilter: 'blur(12px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', WebkitTapHighlightColor: 'transparent', padding: 0,
            boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
          }}>{app.wishlist[product.id] ? Ic.heartFill(T.red, 20) : Ic.heart('rgba(60,60,67,0.65)', 20)}</button>
        </div>

        {/* content sheet */}
        <div style={{
          background: T.bg, borderRadius: '20px 20px 0 0', marginTop: -18,
          position: 'relative', padding: '22px 16px 0',
        }}>
          <h2 style={{
            margin: 0, fontFamily: T.font, fontSize: 23, fontWeight: 700,
            color: T.text, letterSpacing: -0.3, lineHeight: 1.25,
          }}>{product.name}</h2>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
            <span style={{ fontFamily: T.font, fontSize: 26, fontWeight: 700, color: T.accent, letterSpacing: -0.4 }}>
              {formatSum(product.price)}
            </span>
            {product.oldPrice && (
              <span style={{ fontFamily: T.font, fontSize: 16, color: T.ter, textDecoration: 'line-through' }}>
                {formatSum(product.oldPrice)}
              </span>
            )}
            {product.unitName && (
              <span style={{ fontFamily: T.font, fontSize: 16, color: T.sec }}>/ {tr(product.unitName)}</span>
            )}
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12, flexWrap: 'wrap' }}>
            <StockBadge inStock={product.inStock} />
            <span style={{ fontFamily: T.font, fontSize: 14, color: T.sec }}>
              {tr(product.categoryName)}{product.brandName ? ` · ${product.brandName}` : ''}
            </span>
          </div>

          {product.description && (
            <div style={{ borderTop: `0.5px solid ${T.sep}`, marginTop: 18, paddingTop: 16 }}>
              <SectionHeader>{tr('Тавсиф')}</SectionHeader>
              <p style={{
                margin: '8px 0 0', fontFamily: T.font, fontSize: 16, lineHeight: 1.5,
                color: T.text, letterSpacing: -0.2, textWrap: 'pretty',
              }}>{product.description}</p>
            </div>
          )}
        </div>
      </div>

      {/* bottom fixed bar */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        padding: '12px 16px 38px',
        background: 'rgba(255,255,255,0.88)', backdropFilter: 'blur(16px) saturate(180%)',
        WebkitBackdropFilter: 'blur(16px) saturate(180%)',
        borderTop: `0.5px solid ${T.sep}`,
        display: 'flex', flexDirection: 'column', gap: 2,
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 4, marginBottom: 6 }}>
          <TextButton onClick={() => app.toast(tr2('Қўнғироқ', 'Звонок') + ': ' + SHOP_INFO.phone)} style={{ fontSize: 14.5, display: 'flex', alignItems: 'center', gap: 6, padding: '6px 10px' }}>
            {Ic.phone()} {tr('Қўнғироқ қилиш')}
          </TextButton>
          <TextButton onClick={() => app.toast('Telegram: ' + SHOP_INFO.telegram)} style={{ fontSize: 14.5, display: 'flex', alignItems: 'center', gap: 6, padding: '6px 10px' }}>
            {Ic.send()} {tr('Telegram орқали')}
          </TextButton>
        </div>
        {qty === 0 ? (
          <BigButton disabled={!product.inStock} onClick={() => app.addToCart(product.id)}>
            {product.inStock ? tr('Саватга қўшиш') : tr('Тугаган')}
          </BigButton>
        ) : (
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              flex: 1, height: 50, borderRadius: T.radiusBtn, background: T.accentDim,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: T.font, fontSize: 16.5, fontWeight: 600, color: T.accent,
            }}>
              {Ic.check(T.accent, 16)} {tr('Саватда')}
            </div>
            <Stepper qty={qty} onChange={(n) => app.setQty(product.id, n)} />
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { CatalogScreen, ProductDetailScreen, ProductCard, SkeletonCard });
