import 'strings.dart';

/// Formatting helpers ported from shop-data.js.

const String _thinSpace = ' ';

/// 12000 → "12 000 сўм" (thin-space grouped, currency suffix by language).
String formatSum(num? n) {
  if (n == null) return '—';
  final digits = n.round().toString();
  final buf = StringBuffer();
  final len = digits.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(_thinSpace);
    buf.write(digits[i]);
  }
  return '$buf${uiLang == 'ru' ? ' сум' : ' сўм'}';
}

/// Integer → "3"; fractional → "1,5" (comma decimal).
String formatQty(num q) {
  if (q % 1 == 0) return q.toInt().toString();
  return q.toString().replaceAll('.', ',');
}

/// 9-digit local part → "+998 90 123 45 67".
String formatPhone(String? digitsInput) {
  final d = (digitsInput ?? '').replaceAll(RegExp(r'\D'), '');
  final s = d.length > 9 ? d.substring(0, 9) : d;
  var out = '+998';
  if (s.isNotEmpty) out += ' ${s.substring(0, s.length.clamp(0, 2))}';
  if (s.length > 2) out += ' ${s.substring(2, s.length.clamp(0, 5))}';
  if (s.length > 5) out += ' ${s.substring(5, s.length.clamp(0, 7))}';
  if (s.length > 7) out += ' ${s.substring(7, s.length.clamp(0, 9))}';
  return out;
}

/// Strips a leading +998 and all non-digits, capped at 9 digits — used by the
/// phone inputs (mirrors the prototype's onChange regex).
String normalizePhoneInput(String raw) {
  var v = raw.replaceFirst(RegExp(r'^\+?998'), '');
  v = v.replaceAll(RegExp(r'\D'), '');
  return v.length > 9 ? v.substring(0, 9) : v;
}

/// Reformats [input] as a phone number and returns the formatted text together
/// with a caret [offset] that keeps the same number of digits to its left as
/// [cursor] had — so editing the middle of a number no longer jolts the caret
/// to the end.
({String text, int offset}) formatPhoneWithCaret(String input, int cursor) {
  final pos = cursor < 0 ? input.length : cursor.clamp(0, input.length);
  final digitsLeft = input.substring(0, pos).replaceAll(RegExp(r'\D'), '').length;
  final text = formatPhone(normalizePhoneInput(input));
  var seen = 0;
  var offset = text.length;
  for (var i = 0; i < text.length; i++) {
    if (seen >= digitsLeft) {
      offset = i;
      break;
    }
    if (RegExp(r'\d').hasMatch(text[i])) seen++;
  }
  return (text: text, offset: offset);
}

/// Local 9-digit part → API E.164 form "+998901234567".
String phoneToE164(String local9) => '+998${local9.replaceAll(RegExp(r'\D'), '')}';

/// API E.164 "+998901234567" → local 9-digit "901234567".
String phoneFromE164(String e164) {
  var d = e164.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('998')) d = d.substring(3);
  return d.length > 9 ? d.substring(d.length - 9) : d;
}

const _uzMonths = ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
const _ruMonths = ['', 'янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

/// ISO timestamp → short localized date like "8 июн" (adds the year for dates
/// outside the current year, so "8 июн 2025" isn't mistaken for this year).
String formatDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final l = dt.toLocal();
  final months = uiLang == 'ru' ? _ruMonths : _uzMonths;
  final base = '${l.day} ${months[l.month]}';
  return l.year == DateTime.now().year ? base : '$base ${l.year}';
}
