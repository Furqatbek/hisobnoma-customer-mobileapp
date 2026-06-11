// App root — tab navigation, stacks, cart + auth state, device mounting

const SHOP_SCREENS = {
  catalog: (props) => <CatalogScreen {...props} />,
  product: (props) => <ProductDetailScreen {...props} />,
  cart: (props) => <CartScreen {...props} />,
  checkout: (props) => <CheckoutScreen {...props} />,
  success: (props) => <OrderSuccessScreen {...props} />,
  profile: (props) => <ProfileScreen {...props} />,
  login: (props) => <LoginScreen {...props} />,
  status: (props) => <OrderStatusScreen {...props} />,
  notifications: (props) => <NotificationsScreen {...props} />,
  wallet: (props) => <WalletScreen {...props} />,
  coupons: (props) => <CouponsScreen {...props} />,
  referrals: (props) => <ReferralsScreen {...props} />,
  wishlist: (props) => <WishlistScreen {...props} />,
};

const CART_KEY = 'hisobnoma-shop-cart-v1';
const WISH_KEY = 'hisobnoma-shop-wishlist-v1';

function loadWishlist() {
  try {
    const raw = localStorage.getItem(WISH_KEY);
    if (raw) {
      const obj = JSON.parse(raw);
      const clean = {};
      Object.keys(obj).forEach(k => {
        if (window.ShopData.productById(Number(k))) clean[k] = obj[k];
      });
      return clean;
    }
  } catch (e) {}
  // first run: seed so back-in-stock / discount alerts are demoable
  return {
    105: { addedOutOfStock: true },  // Гуруч — back in stock
    109: {},                          // Persil — discounted
    102: {},                          // Pepsi — still out of stock
  };
}

function loadCart() {
  try {
    const raw = localStorage.getItem(CART_KEY);
    if (!raw) return {};
    const obj = JSON.parse(raw);
    const clean = {};
    Object.keys(obj).forEach(k => {
      if (window.ShopData.productById(Number(k)) && obj[k] > 0) clean[k] = obj[k];
    });
    return clean;
  } catch (e) { return {}; }
}

// ── Tab bar ──────────────────────────────────────────────────
function ShopTabBar({ tab, setTab, cartCount, bounce, wishAlertCount }) {
  const tabs = [
    { id: 'catalog', label: 'Каталог', icon: Ic.grid },
    { id: 'cart', label: 'Сават', icon: Ic.cart },
    { id: 'wallet', label: 'Ҳамён', icon: Ic.qr },
    { id: 'wishlist', label: 'Севимлилар', icon: Ic.heart },
    { id: 'profile', label: 'Профил', icon: Ic.person },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 40,
      background: 'rgba(255,255,255,0.88)',
      backdropFilter: 'blur(18px) saturate(180%)', WebkitBackdropFilter: 'blur(18px) saturate(180%)',
      borderTop: `0.5px solid ${T.sep}`,
      display: 'flex', paddingBottom: 26, paddingTop: 6,
    }}>
      {tabs.map(t => {
        const active = tab === t.id;
        const color = active ? T.accent : 'rgba(60,60,67,0.55)';
        return (
          <button key={t.id} onClick={() => setTab(t.id)} style={{
            flex: 1, border: 'none', background: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '4px 0', WebkitTapHighlightColor: 'transparent', position: 'relative',
          }}>
            <div style={{ position: 'relative' }}>
              {t.icon(color, 25)}
              {t.id === 'cart' && cartCount > 0 && (
                <span style={{
                  position: 'absolute', top: -5, right: -10, minWidth: 17, height: 17,
                  borderRadius: 100, background: T.red, color: '#fff',
                  fontFamily: T.font, fontSize: 11, fontWeight: 700,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  padding: '0 4px', boxSizing: 'border-box',
                  animation: bounce ? 'shopBounce 0.4s cubic-bezier(0.34,1.56,0.64,1)' : 'none',
                }}>{cartCount}</span>
              )}
              {t.id === 'wishlist' && wishAlertCount > 0 && (
                <span style={{
                  position: 'absolute', top: -5, right: -10, minWidth: 17, height: 17,
                  borderRadius: 100, background: T.accent, color: '#fff',
                  fontFamily: T.font, fontSize: 11, fontWeight: 700,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  padding: '0 4px', boxSizing: 'border-box',
                }}>{wishAlertCount}</span>
              )}
            </div>
            <span style={{
              fontFamily: T.font, fontSize: 10.5, fontWeight: active ? 600 : 500,
              color, letterSpacing: 0,
            }}>{tr(t.label)}</span>
          </button>
        );
      })}
    </div>
  );
}

// ── App ──────────────────────────────────────────────────────
function ShopApp() {
  const { useState, useRef, useEffect } = React;
  const [tab, setTabState] = useState('catalog');
  const [lang, setLangState] = useState(() => {
    try { return localStorage.getItem('hisobnoma-shop-lang') || 'uz'; } catch (e) { return 'uz'; }
  });
  window.__shopLang = lang; // read by tr()/tr2()/formatSum before children render
  const [stacks, setStacks] = useState({
    catalog: [{ name: 'catalog' }],
    wishlist: [{ name: 'wishlist' }],
    cart: [{ name: 'cart' }],
    wallet: [{ name: 'wallet' }],
    profile: [{ name: 'profile' }],
  });
  const [motion, setMotion] = useState('none'); // push | pop | none
  const [cart, setCart] = useState(loadCart);
  const [wishlist, setWishlist] = useState(loadWishlist);
  const [user, setUser] = useState(null);
  const [sessionOrders, setSessionOrders] = useState([]);
  const [orderCounter, setOrderCounter] = useState(13);
  const [lastOrderPhone, setLastOrderPhone] = useState('');
  const [toastMsg, setToastMsg] = useState('');
  const [toastShow, setToastShow] = useState(false);
  const [bounce, setBounce] = useState(false);
  const toastTimer = useRef(null);
  const bounceTimer = useRef(null);

  useEffect(() => {
    try { localStorage.setItem(CART_KEY, JSON.stringify(cart)); } catch (e) {}
  }, [cart]);

  useEffect(() => {
    try { localStorage.setItem(WISH_KEY, JSON.stringify(wishlist)); } catch (e) {}
  }, [wishlist]);

  const wishAlert = (id) => {
    const p = window.ShopData.productById(id);
    const entry = wishlist[id];
    if (!p || !entry) return null;
    if (entry.addedOutOfStock && p.inStock) return 'back';
    if (p.oldPrice && p.oldPrice > p.price) return 'discount';
    return null;
  };
  const wishAlertCount = Object.keys(wishlist).map(Number).filter(id => wishAlert(id)).length;

  const stack = stacks[tab];
  const screen = stack[stack.length - 1];
  const cartCount = Object.values(cart).reduce((s, q) => s + q, 0);

  const toast = (msg) => {
    setToastMsg(msg);
    setToastShow(true);
    clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToastShow(false), 1800);
  };

  const pingBadge = () => {
    setBounce(false);
    clearTimeout(bounceTimer.current);
    bounceTimer.current = setTimeout(() => setBounce(true), 16);
  };

  const app = {
    cart, user, lastOrderPhone, toast, lang,
    wishlist, wishAlert,
    toggleWish: (id) => {
      setWishlist(prev => {
        const next = { ...prev };
        if (next[id]) {
          delete next[id];
          toast(tr('Севимлилардан олиб ташланди'));
        } else {
          const p = window.ShopData.productById(id);
          next[id] = { addedOutOfStock: p ? !p.inStock : false };
          toast(tr('Севимлиларга қўшилди'));
        }
        return next;
      });
    },
    setLang: (l) => {
      setLangState(l);
      try { localStorage.setItem('hisobnoma-shop-lang', l); } catch (e) {}
    },
    setTab: (t) => { setMotion('none'); setTabState(t); },
    push: (s) => {
      setMotion('push');
      setStacks(prev => ({ ...prev, [tab]: [...prev[tab], s] }));
    },
    pop: () => {
      setMotion('pop');
      setStacks(prev => {
        const st = prev[tab];
        if (st.length <= 1) return prev;
        return { ...prev, [tab]: st.slice(0, -1) };
      });
    },
    replace: (s) => {
      setMotion('push');
      setStacks(prev => ({ ...prev, [tab]: [{ name: prev[tab][0].name }, s] }));
    },
    resetCartStack: () => {
      setMotion('none');
      setStacks(prev => ({ ...prev, cart: [{ name: 'cart' }] }));
    },
    addToCart: (id) => {
      setCart(prev => ({ ...prev, [id]: (prev[id] || 0) + 1 }));
      pingBadge();
    },
    setQty: (id, qty) => {
      setCart(prev => {
        const next = { ...prev };
        if (qty <= 0) delete next[id]; else next[id] = qty;
        return next;
      });
    },
    login: ({ phone, name }) => setUser({ phone, name }),
    logout: () => { setUser(null); setMotion('none'); },
    allOrders: () => [...sessionOrders, ...window.ShopData.SAMPLE_ORDERS],
    placeOrder: ({ name, phone, fee, subtotal }) => {
      const { productById } = window.ShopData;
      const lines = Object.keys(cart).map(Number).map(id => {
        const p = productById(id);
        return { productName: p.name, quantity: cart[id], unitPrice: p.price, lineTotal: p.price * cart[id] };
      });
      const order = {
        orderNumber: 'WO-' + String(orderCounter).padStart(6, '0'),
        status: 'NEW', phone, customerName: name,
        deliveryFee: fee, totalAmount: subtotal + fee, date: 'бугун', lines,
      };
      setOrderCounter(c => c + 1);
      setSessionOrders(prev => [order, ...prev]);
      setLastOrderPhone(phone);
      setCart({});
      return order;
    },
  };

  const Screen = SHOP_SCREENS[screen.name];
  const screenKey = tab + '-' + stack.length + '-' + screen.name;
  // Animations are applied only transiently during navigation, then cleared —
  // steady-state DOM carries no animation (robust for capture/reduced motion).
  useEffect(() => {
    if (motion !== 'none') {
      const t = setTimeout(() => setMotion('none'), 400);
      return () => clearTimeout(t);
    }
  }, [motion, screenKey]);
  const anim = motion === 'push' ? 'shopSlideInRight 0.32s cubic-bezier(0.3,0.9,0.3,1)'
    : motion === 'pop' ? 'shopSlideInLeft 0.3s cubic-bezier(0.3,0.9,0.3,1)'
    : 'none';
  const showTabBar = stack.length === 1;

  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', background: T.bg }}>
      <div key={screenKey} style={{ position: 'absolute', inset: 0, animation: anim }}>
        <Screen app={app} screen={screen} />
      </div>
      {showTabBar && <ShopTabBar tab={tab} setTab={app.setTab} cartCount={cartCount} bounce={bounce} wishAlertCount={wishAlertCount} />}
      <Toast message={toastMsg} show={toastShow} />
    </div>
  );
}

// ── Mount: device frame centered + scaled to viewport ───────
function ShopRoot() {
  const { useState, useEffect } = React;
  const [scale, setScale] = useState(1);

  useEffect(() => {
    const fit = () => {
      const s = Math.min(1, (window.innerHeight - 48) / 874, (window.innerWidth - 32) / 402);
      setScale(Math.max(0.4, s));
    };
    fit();
    window.addEventListener('resize', fit);
    return () => window.removeEventListener('resize', fit);
  }, []);

  return (
    <div style={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: '#E8E8E6',
    }}>
      <div style={{
        width: 402 * scale, height: 874 * scale, overflow: 'visible',
      }} data-screen-label="Hisobnoma Shop">
        <div style={{ transform: `scale(${scale})`, transformOrigin: 'top left' }}>
          <IOSDevice width={402} height={874}>
            <div style={{ position: 'absolute', inset: 0 }}>
              <ShopApp />
            </div>
          </IOSDevice>
        </div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<ShopRoot />);
