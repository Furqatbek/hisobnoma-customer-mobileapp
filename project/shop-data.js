// Hisobnoma Shop — mock data + helpers (per DESIGN_BRIEF.md)

window.__shopLang = window.__shopLang || 'uz';

// Uzbek (Cyrillic) → Russian translations. tr(s) picks based on current language.
const RU_DICT = {
  // tabs / nav
  'Сават': 'Корзина', 'Ҳамён': 'Кошелёк', 'Профил': 'Профиль',
  // catalog
  'Қидириш...': 'Поиск...', 'Барчаси': 'Все',
  'Ичимликлар': 'Напитки', 'Озиқ-овқат': 'Продукты', 'Маиший кимё': 'Бытовая химия',
  'Ҳеч нарса топилмади': 'Ничего не найдено',
  'Тугаган': 'Нет в наличии', 'Мавжуд': 'В наличии',
  'Тавсиф': 'Описание', 'дона': 'шт.',
  'Қўнғироқ қилиш': 'Позвонить', 'Telegram орқали': 'Через Telegram',
  'Саватга қўшиш': 'В корзину', 'Саватда': 'В корзине',
  // cart
  'Сават бўш': 'Корзина пуста', 'Каталогга қайтиш': 'Вернуться в каталог',
  'Ўчириш': 'Удалить', 'Ўчириш учун чапга суринг': 'Смахните влево, чтобы удалить',
  'Жами': 'Итого', 'Буюртма бериш': 'Оформить заказ',
  // checkout
  'Буюртма': 'Заказ', 'Контакт': 'Контакты', 'Исмингиз': 'Ваше имя',
  'Етказиб бериш': 'Доставка', 'Туман': 'Район', 'Қишлоқ / маҳалла': 'Село / махалля',
  'Қўшимча': 'Дополнительно', 'Изоҳ (ихтиёрий)': 'Комментарий (необязательно)',
  'Жами тўлов': 'Итого к оплате', 'Буюртмани юбориш': 'Отправить заказ',
  'Исмингизни киритинг': 'Введите имя', 'Телефон рақам нотўғри': 'Неверный номер телефона',
  'Тошкент шаҳар': 'Ташкент (город)', 'Тошкент вилояти': 'Ташкентская область',
  'Чилонзор': 'Чиланзар', 'Юнусобод': 'Юнусабад', 'Мирзо Улуғбек': 'Мирзо-Улугбек',
  'Зангиота': 'Зангиата', 'Қибрай': 'Кибрай',
  // success / status
  'Буюртмангиз қабул қилинди!': 'Ваш заказ принят!',
  'Тез орада сиз билан боғланамиз...': 'Мы скоро свяжемся с вами...',
  'Буюртма ҳолатини текшириш': 'Проверить статус заказа',
  'Нусха олинди': 'Скопировано',
  'Буюртма ҳолати': 'Статус заказа', 'Буюртма рақами (WO-000012)': 'Номер заказа (WO-000012)',
  'Излаш': 'Найти',
  'Буюртма топилмади. Рақам ва телефонни текширинг.': 'Заказ не найден. Проверьте номер и телефон.',
  // statuses
  'Янги': 'Новый', 'Тасдиқланган': 'Подтверждён', 'Етказилмоқда': 'Доставляется',
  'Бажарилган': 'Выполнен', 'Бекор қилинган': 'Отменён',
  // profile / login
  'Буюртмалар тарихини кўриш учун тизимга киринг': 'Войдите, чтобы видеть историю заказов',
  'Кириш': 'Войти', 'Купонлар': 'Купоны', 'Дўстларни таклиф қилиш': 'Пригласить друзей',
  'Билдиришномалар': 'Уведомления', 'Буюртмалар': 'Заказы',
  'Ҳозирча буюртмалар йўқ': 'Пока нет заказов', 'Чиқиш': 'Выйти',
  'Телефон рақамингизга SMS код юборамиз': 'Отправим SMS-код на ваш номер телефона',
  'Код юбориш': 'Отправить код', 'Рақамни ўзгартириш': 'Изменить номер',
  'Демо: исталган 6 хонали код': 'Демо: любой 6-значный код',
  'Исмингиз (ихтиёрий)': 'Ваше имя (необязательно)', 'Тасдиқлаш': 'Подтвердить',
  'Қайта юбориш': 'Отправить снова', 'Код қайта юборилди': 'Код отправлен снова',
  'Код нотўғри ёки муддати ўтган': 'Неверный или просроченный код',
  // notifications
  'Буюртмангиз тасдиқланди': 'Ваш заказ подтверждён',
  'WO-000012 буюртмангиз тасдиқланди ва тез орада етказилади.': 'Заказ WO-000012 подтверждён и скоро будет доставлен.',
  'Кешбек тушди': 'Кешбэк начислен',
  '+1 530 сўм кешбек ҳамёнингизга қўшилди.': '+1 530 сум кешбэка зачислено в ваш кошелёк.',
  '10% чегирма': 'Скидка 10%',
  'Маиший кимё маҳсулотларига 15 июнгача 10% чегирма.': 'Скидка 10% на бытовую химию до 15 июня.',
  'Буюртма бажарилди': 'Заказ выполнен',
  'WO-000007 буюртмангиз муваффақиятли етказилди.': 'Заказ WO-000007 успешно доставлен.',
  'Бугун, 10:24': 'Сегодня, 10:24', 'Бугун, 10:20': 'Сегодня, 10:20', 'Кеча': 'Вчера',
  '29 май': '29 мая', '8 июн': '8 июня', '25 май': '25 мая', 'бугун': 'сегодня',
  // wallet
  'Кешбек ҳамёни': 'Кешбэк-кошелёк', 'Кешбек баланс': 'Баланс кешбэка',
  'Кассада QR кодни кўрсатинг — кешбек ҳамёнингизга ўтказилади': 'Покажите QR-код на кассе — кешбэк поступит в ваш кошелёк',
  'Ҳаракатлар': 'Операции',
  'WO-000012 — кешбек': 'WO-000012 — кешбэк', 'WO-000007 — кешбек': 'WO-000007 — кешбэк',
  'Харидда ишлатилди': 'Использовано при покупке',
  // coupons
  'Фаол': 'Активные', 'Ишлатилган': 'Использованные',
  'Ҳозирча купонлар йўқ': 'Пока нет купонов', 'Код нусха олинди': 'Код скопирован',
  'Барча ичимликларга': 'На все напитки', '50 000 сўмдан ортиқ харидга': 'При покупке от 50 000 сум',
  'Етказиб бериш — Тошкент шаҳри': 'Доставка — город Ташкент', 'Биринчи буюртма учун': 'За первый заказ',
  '30 июнгача': 'до 30 июня', '15 июлгача': 'до 15 июля', '20 июнгача': 'до 20 июня',
  '29 майда ишлатилган': 'использован 29 мая',
  'Бепул': 'Бесплатно', '5 000 сўм': '5 000 сум', '10 000 сўм': '10 000 сум',
  // referrals
  'Telegram орқали улашиш': 'Поделиться в Telegram',
  'Таклиф қилинган': 'Приглашено', 'Олинган бонус': 'Получено бонусов',
  'Қандай ишлайди': 'Как это работает',
  'Кодингизни дўстингизга юборинг': 'Отправьте код другу',
  'Дўстингиз буюртма беришда кодни киритади': 'Друг вводит код при заказе',
  'Иккалангиз ҳам кешбек оласиз': 'Вы оба получаете кешбэк',
  // wishlist
  'Севимлилар': 'Избранное', 'Севимлилар бўш': 'В избранном пусто',
  'Яна сотувда': 'Снова в продаже', 'чегирма': 'скидка',
  'Севимлиларга қўшилди': 'Добавлено в избранное',
  'Севимлилардан олиб ташланди': 'Удалено из избранного',
  'Саватга қўшилди': 'Добавлено в корзину',
};

// translate: returns Russian when current language is 'ru' and a translation exists
function tr(s) {
  return (window.__shopLang === 'ru' && RU_DICT[s]) || s;
}
// inline two-language literal
function tr2(uz, ru) {
  return window.__shopLang === 'ru' ? ru : uz;
}

const SHOP_INFO = {
  name: 'Hisobnoma Shop',
  phone: '+998 71 200 00 00',
  telegram: '@hisobnoma_shop',
};

const CATEGORIES = [
  { id: 1, name: 'Ичимликлар' },
  { id: 2, name: 'Озиқ-овқат' },
  { id: 3, name: 'Маиший кимё' },
];

const PRODUCTS = [
  {
    id: 100, name: 'Coca-Cola 1.5л', shortDescription: 'Газли ичимлик',
    description: 'Coca-Cola классик таъми, 1.5 литрлик шиша. Совуқ ҳолда истеъмол қилиш тавсия этилади.',
    price: 12000, categoryId: 1, categoryName: 'Ичимликлар', brandName: 'Coca-Cola',
    unitName: 'дона', inStock: true, images: 2,
  },
  {
    id: 101, name: 'Fanta Апельсин 1л', shortDescription: 'Газли ичимлик',
    description: 'Апельсин таъмли газли ичимлик, 1 литрлик пластик идиш.',
    price: 9000, oldPrice: 11000, categoryId: 1, categoryName: 'Ичимликлар', brandName: 'Fanta',
    unitName: 'дона', inStock: true, images: 1,
  },
  {
    id: 102, name: 'Pepsi 0.5л', shortDescription: 'Газли ичимлик',
    description: 'Pepsi газли ичимлиги, 0.5 литрлик шиша.',
    price: 6000, categoryId: 1, categoryName: 'Ичимликлар', brandName: 'Pepsi',
    unitName: 'дона', inStock: false, images: 1,
  },
  {
    id: 103, name: 'Nestlé Pure Life сув 5л', shortDescription: 'Ичимлик суви',
    description: 'Тоза ичимлик суви, 5 литрлик идиш. Оила учун қулай ҳажм.',
    price: 8000, categoryId: 1, categoryName: 'Ичимликлар', brandName: 'Nestlé',
    unitName: 'дона', inStock: true, images: 1,
  },
  {
    id: 104, name: 'Макарон «Барака» 400г', shortDescription: 'Юқори навли макарон',
    description: 'Юқори навли буғдой унидан тайёрланган макарон маҳсулоти, 400 грамм.',
    price: 7500, categoryId: 2, categoryName: 'Озиқ-овқат', brandName: 'Барака',
    unitName: 'дона', inStock: true, images: 1,
  },
  {
    id: 105, name: 'Гуруч (лазер)', shortDescription: 'Сара навли гуруч',
    description: 'Лазер навли сара гуруч. Ош ва бошқа таомлар учун мос.',
    price: 18000, categoryId: 2, categoryName: 'Озиқ-овқат', brandName: null,
    unitName: 'кг', inStock: true, images: 1,
  },
  {
    id: 106, name: 'Ўсимлик ёғи 1л', shortDescription: 'Рафинацияланган ёғ',
    description: 'Рафинацияланган дезодорацияланган ўсимлик ёғи, 1 литр.',
    price: 22000, categoryId: 2, categoryName: 'Озиқ-овқат', brandName: null,
    unitName: 'дона', inStock: true, images: 1,
  },
  {
    id: 107, name: 'Шакар', shortDescription: 'Оқ шакар',
    description: 'Юқори сифатли оқ шакар, вазн бўйича сотилади.',
    price: 13000, categoryId: 2, categoryName: 'Озиқ-овқат', brandName: null,
    unitName: 'кг', inStock: true, images: 1,
  },
  {
    id: 108, name: 'Чой «Ahmad» кўк 100г', shortDescription: 'Кўк чой',
    description: 'Ahmad Tea кўк чойи, 100 граммлик қути.',
    price: 15000, categoryId: 2, categoryName: 'Озиқ-овқат', brandName: 'Ahmad Tea',
    unitName: 'дона', inStock: true, images: 1,
  },
  {
    id: 109, name: 'Persil кир ювиш кукуни 3кг', shortDescription: 'Автомат кир ювиш кукуни',
    description: 'Persil автомат кир ювиш кукуни, 3 килограммлик қути. Барча мато турлари учун.',
    price: 75000, oldPrice: 89000, categoryId: 3, categoryName: 'Маиший кимё', brandName: 'Persil',
    unitName: 'дона', inStock: true, images: 1,
  },
  {
    id: 110, name: 'Fairy идиш ювиш воситаси 450мл', shortDescription: 'Идиш ювиш суюқлиги',
    description: 'Fairy идиш ювиш воситаси, лимон ҳидли, 450 мл.',
    price: 16000, categoryId: 3, categoryName: 'Маиший кимё', brandName: 'Fairy',
    unitName: 'дона', inStock: true, images: 1,
  },
  {
    id: 111, name: 'Domestos 750мл', shortDescription: 'Тозалаш воситаси',
    description: 'Domestos универсал тозалаш ва дезинфекция воситаси, 750 мл.',
    price: 14000, categoryId: 3, categoryName: 'Маиший кимё', brandName: 'Domestos',
    unitName: 'дона', inStock: false, images: 1,
  },
];

const REGIONS = [
  { id: 1, name: 'Тошкент шаҳар', deliveryFee: 0 },
  { id: 2, name: 'Тошкент вилояти', deliveryFee: 15000 },
];

const VILLAGES = [
  { id: 11, name: 'Чилонзор', regionId: 1 },
  { id: 12, name: 'Юнусобод', regionId: 1 },
  { id: 13, name: 'Мирзо Улуғбек', regionId: 1 },
  { id: 21, name: 'Зангиота', regionId: 2 },
  { id: 22, name: 'Қибрай', regionId: 2 },
];

const ORDER_STATUS = {
  NEW:        { label: 'Янги',           color: '#E8730C', bg: 'rgba(232,115,12,0.12)' },
  CONFIRMED:  { label: 'Тасдиқланган',   color: '#1D6FE0', bg: 'rgba(29,111,224,0.10)' },
  DELIVERING: { label: 'Етказилмоқда',   color: '#B07E0A', bg: 'rgba(176,126,10,0.12)' },
  COMPLETED:  { label: 'Бажарилган',     color: '#1E8A4C', bg: 'rgba(30,138,76,0.12)' },
  CANCELLED:  { label: 'Бекор қилинган', color: '#D63B2F', bg: 'rgba(214,59,47,0.10)' },
};

// Pre-existing order for the lookup demo (phone +998 90 123 45 67)
const SAMPLE_ORDERS = [
  {
    orderNumber: 'WO-000012', status: 'CONFIRMED', phone: '901234567',
    deliveryFee: 15000, totalAmount: 51000, date: '8 июн',
    lines: [
      { productName: 'Coca-Cola 1.5л', quantity: 3, unitPrice: 12000, lineTotal: 36000 },
    ],
  },
  {
    orderNumber: 'WO-000007', status: 'COMPLETED', phone: '901234567',
    deliveryFee: 0, totalAmount: 31000, date: '29 май',
    lines: [
      { productName: 'Fairy идиш ювиш воситаси 450мл', quantity: 1, unitPrice: 16000, lineTotal: 16000 },
      { productName: 'Макарон «Барака» 400г', quantity: 2, unitPrice: 7500, lineTotal: 15000 },
    ],
  },
];

// ── Notifications / Wallet / Coupons / Referral mock data ──

const NOTIFICATIONS = [
  { id: 1, type: 'order',    title: 'Буюртмангиз тасдиқланди', body: 'WO-000012 буюртмангиз тасдиқланди ва тез орада етказилади.', date: 'Бугун, 10:24', unread: true },
  { id: 2, type: 'cashback', title: 'Кешбек тушди', body: '+1 530 сўм кешбек ҳамёнингизга қўшилди.', date: 'Бугун, 10:20', unread: true },
  { id: 3, type: 'promo',    title: '10% чегирма', body: 'Маиший кимё маҳсулотларига 15 июнгача 10% чегирма.', date: 'Кеча', unread: false },
  { id: 4, type: 'order',    title: 'Буюртма бажарилди', body: 'WO-000007 буюртмангиз муваффақиятли етказилди.', date: '29 май', unread: false },
];

const WALLET = {
  balance: 24500,
  cashbackRate: '3%',
  transactions: [
    { id: 1, amount: 1530,  label: 'WO-000012 — кешбек', date: '8 июн' },
    { id: 2, amount: 930,   label: 'WO-000007 — кешбек', date: '29 май' },
    { id: 3, amount: -5000, label: 'Харидда ишлатилди',  date: '25 май' },
  ],
};

const COUPONS = [
  { id: 1, value: '−10%', title: 'Барча ичимликларга', code: 'DRINK10', until: '30 июнгача', used: false },
  { id: 2, value: '5 000 сўм', title: '50 000 сўмдан ортиқ харидга', code: 'SAVE5000', until: '15 июлгача', used: false },
  { id: 3, value: 'Бепул', title: 'Етказиб бериш — Тошкент шаҳри', code: 'FREEDEL', until: '20 июнгача', used: false },
  { id: 4, value: '10 000 сўм', title: 'Биринчи буюртма учун', code: 'WELCOME', until: '29 майда ишлатилган', used: true },
];

const REFERRAL = {
  code: 'HISOB-9012',
  bonus: 10000,
  invited: 3,
  earned: 30000,
};

// ── Helpers ──────────────────────────────────────────────────

function formatSum(n) {
  if (n === null || n === undefined) return '—';
  const s = String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '\u2009');
  return s + (window.__shopLang === 'ru' ? ' сум' : ' сўм');
}

function formatQty(q) {
  return (q % 1 === 0) ? String(q) : String(q).replace('.', ',');
}

// 9-digit local part → "+998 90 123 45 67"
function formatPhone(digits) {
  const d = (digits || '').replace(/\D/g, '').slice(0, 9);
  let out = '+998';
  if (d.length > 0) out += ' ' + d.slice(0, 2);
  if (d.length > 2) out += ' ' + d.slice(2, 5);
  if (d.length > 5) out += ' ' + d.slice(5, 7);
  if (d.length > 7) out += ' ' + d.slice(7, 9);
  return out;
}

function productById(id) { return PRODUCTS.find(p => p.id === id); }

window.ShopData = {
  SHOP_INFO, CATEGORIES, PRODUCTS, REGIONS, VILLAGES,
  ORDER_STATUS, SAMPLE_ORDERS,
  NOTIFICATIONS, WALLET, COUPONS, REFERRAL,
  formatSum, formatQty, formatPhone, productById,
};
window.tr = tr;
window.tr2 = tr2;
