import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------- Settings ----------
const String kTelegramUser = '@Itz_Luxurious';
const String kTelegramLink = 'https://t.me/Itz_Luxurious';
// ------------------------------

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KiranaApp());
}

class Pal {
  final Color bg, surface, line, accent, onAccent, text, muted, accentText;
  const Pal(this.bg, this.surface, this.line, this.accent, this.onAccent,
      this.text, this.muted, this.accentText);
}

const Pal kLight = Pal(Color(0xFFF6F9FD), Color(0xFFFFFFFF), Color(0xFFE1E8F2),
    Color(0xFF4A9BEA), Color(0xFFFFFFFF), Color(0xFF1B2430), Color(0xFF6B7785), Color(0xFF2F7FD0));
const Pal kDark = Pal(Color(0xFF0D141C), Color(0xFF16212C), Color(0xFF26384A),
    Color(0xFF5AA9F0), Color(0xFF06121D), Color(0xFFEAF1F8), Color(0xFF8CA0B3), Color(0xFF5AA9F0));

String n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
String m(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
String two(int v) => v.toString().padLeft(2, '0');

class Res {
  final String big, sub, note, line;
  final double grams, amt, price;
  const Res(this.big, this.sub, this.note, this.line, this.grams, this.amt, this.price);
}

class BillItem {
  final String name;
  final double price, grams, amt;
  const BillItem(this.name, this.price, this.grams, this.amt);
}

class Hist {
  final String time, rate, result;
  const Hist(this.time, this.rate, this.result);
}

class KiranaApp extends StatelessWidget {
  const KiranaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kirana Kata',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF4A9BEA),
        ),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _dark = false, _hi = true, _p2w = true;
  int _tab = 0;
  final _price = TextEditingController();
  final _input = TextEditingController();
  final _bName = TextEditingController();
  final _bPrice = TextEditingController();
  final _bGrams = TextEditingController();
  final List<BillItem> _bill = [];
  final List<Hist> _hist = [];

  Pal get p => _dark ? kDark : kLight;
  String t(String hi, String en) => _hi ? hi : en;
  void _r() => setState(() {});

  List<BoxShadow> get _sh => [
        BoxShadow(
            color: Colors.black.withValues(alpha: _dark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3)),
      ];

  @override
  void initState() {
    super.initState();
    for (final c in [_price, _input, _bName, _bPrice, _bGrams]) {
      c.addListener(_r);
    }
  }

  @override
  void dispose() {
    for (final c in [_price, _input, _bName, _bPrice, _bGrams]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String s) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(s), duration: const Duration(seconds: 2)));

  // ---------- logic ----------
  Res? get _res {
    final double pr = double.tryParse(_price.text) ?? 0;
    final double iv = double.tryParse(_input.text) ?? 0;
    if (pr <= 0 || iv <= 0) return null;
    if (_p2w) {
      final double ex = iv / pr * 1000;
      final double g = ((ex / 5).round() * 5).toDouble();
      final String kg = g >= 1000 ? '  ≈ ${(g / 1000).toStringAsFixed(2)} ${t('किलो', 'kg')}' : '';
      return Res('${g.round()}g', '${t('सटीक', 'Exact')}: ${ex.toStringAsFixed(1)}g$kg',
          t('नज़दीकी 5 ग्राम में गोल', 'Rounded to nearest 5g'), '₹${n(iv)} → ${g.round()}g', g, iv, pr);
    }
    final double a = pr * iv / 1000;
    return Res('₹${a.round()}', '${t('सटीक', 'Exact')}: ₹${a.toStringAsFixed(2)}', '',
        '${n(iv)}g → ₹${a.round()}', iv, a, pr);
  }

  double get _total => _bill.fold(0.0, (s, e) => s + e.amt);

  String get _billText {
    final StringBuffer b = StringBuffer('🧾 ${t('किराना बिल', 'Kirana Bill')}\n');
    for (int i = 0; i < _bill.length; i++) {
      final BillItem it = _bill[i];
      final String nm = it.name.isEmpty ? '${t('सामान', 'Item')} ${i + 1}' : it.name;
      b.writeln('${i + 1}. $nm — ${n(it.grams)}g × ₹${n(it.price)}/${t('किलो', 'kg')} = ₹${m(it.amt)}');
    }
    b.write('${t('कुल', 'Total')}: ₹${m(_total)}');
    return b.toString();
  }

  void _saveHist(Res r) {
    final DateTime d = DateTime.now();
    _hist.insert(0, Hist('${two(d.hour)}:${two(d.minute)}', '₹${n(r.price)}/${t('किलो', 'kg')}', r.line));
    if (_hist.length > 50) _hist.removeLast();
    HapticFeedback.lightImpact();
    _snack(t('हिस्ट्री में सेव हो गया', 'Saved to history'));
  }

  void _addToBill(Res r) {
    setState(() => _bill.insert(0, BillItem('', r.price, r.grams, r.amt)));
    HapticFeedback.lightImpact();
    _snack(t('बिल में जुड़ गया', 'Added to bill'));
  }

  void _addBillManual() {
    final double pr = double.tryParse(_bPrice.text) ?? 0;
    final double g = double.tryParse(_bGrams.text) ?? 0;
    if (pr <= 0 || g <= 0) return;
    setState(() {
      _bill.insert(0, BillItem(_bName.text.trim(), pr, g, pr * g / 1000));
      _bName.clear();
      _bPrice.clear();
      _bGrams.clear();
    });
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
  }

  void _clearCalc() {
    HapticFeedback.lightImpact();
    _price.clear();
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  void _copy(String s, String msg) {
    Clipboard.setData(ClipboardData(text: s));
    _snack(msg);
  }

  Future<void> _openTelegram() async {
    try {
      final bool ok = await launchUrl(Uri.parse(kTelegramLink), mode: LaunchMode.externalApplication);
      if (!ok) _copy(kTelegramUser, t('कॉपी हो गया, Telegram में खोजिए', 'Copied, search it in Telegram'));
    } catch (_) {
      _copy(kTelegramUser, t('कॉपी हो गया, Telegram में खोजिए', 'Copied, search it in Telegram'));
    }
  }

  // ---------- small UI helpers ----------
  OutlineInputBorder _ob(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));

  Widget _label(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(s, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: p.muted)));

  Widget _field(TextEditingController c, String hint,
      {String prefix = '', String suffix = '', bool num = true, double size = 30}) {
    final bool center = num;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: _sh),
      child: TextField(
        controller: c,
        cursorColor: p.accent,
        textAlign: center ? TextAlign.center : TextAlign.start,
        keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: num ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: p.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: size - 8, fontWeight: FontWeight.w400, color: p.muted.withValues(alpha: 0.7)),
          prefixIcon: center
              ? (prefix.isEmpty
                  ? const SizedBox(width: 52)
                  : SizedBox(
                      width: 52,
                      child: Center(
                          child: Text(prefix.trim(),
                              style: TextStyle(fontSize: size - 2, fontWeight: FontWeight.w500, color: p.accentText)))))
              : null,
          suffixIcon: center
              ? (suffix.isEmpty
                  ? const SizedBox(width: 52)
                  : SizedBox(
                      width: 52,
                      child: Center(
                          child: Text(suffix.trim(),
                              style: TextStyle(fontSize: size - 8, fontWeight: FontWeight.w500, color: p.accentText)))))
              : null,
          filled: true,
          fillColor: p.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: size > 24 ? 16 : 14),
          enabledBorder: _ob(p.line, 1),
          focusedBorder: _ob(p.accent, 2),
        ),
      ),
    );
  }

  Widget _chips(TextEditingController c, List<(String, int)> items) {
    final List<Widget> kids = [];
    for (int i = 0; i < items.length; i++) {
      final (String, int) it = items[i];
      final bool sel = c.text == '${it.$2}';
      if (i > 0) kids.add(const SizedBox(width: 6));
      kids.add(Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            c.text = '${it.$2}';
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: sel ? p.accent : p.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: sel ? p.accent : p.line, width: 1),
              boxShadow: sel ? [] : _sh,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(it.$1,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500, color: sel ? p.onAccent : p.text)),
            ),
          ),
        ),
      ));
    }
    return Row(children: kids);
  }

  Widget _btn(String label, IconData icon, VoidCallback? onTap, {bool filled = false}) {
    final RoundedRectangleBorder shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const TextStyle ts = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return SizedBox(
      height: 52,
      child: filled
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label, style: ts),
              style: FilledButton.styleFrom(
                  elevation: 3,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  disabledBackgroundColor: p.line,
                  shape: shape))
          : DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: _sh),
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(icon),
                label: Text(label, style: ts),
                style: OutlinedButton.styleFrom(
                    backgroundColor: p.surface,
                    foregroundColor: p.accentText,
                    side: BorderSide(color: p.line, width: 1),
                    shape: shape),
              ),
            ),
    );
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line, width: 1),
            boxShadow: _sh),
        child: child,
      );

  // ---------- header ----------
  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 6, 6),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle, boxShadow: _sh),
            child: Icon(Icons.balance_rounded, color: p.onAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t('किराना काँटा', 'Kirana Kata'),
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: p.text)),
          ),
          TextButton(
            onPressed: () => setState(() => _hi = !_hi),
            child: Text(_hi ? 'EN' : 'हिं',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.accentText)),
          ),
          IconButton(
            onPressed: () => setState(() => _dark = !_dark),
            icon: Icon(_dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: p.accentText),
          ),
        ]),
      );

  // ---------- pages ----------
  Widget _calcPage() {
    final Res? r = _res;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _label(t('एक किलो की कीमत', 'Price per kg')),
        _field(_price, t('कीमत डालें', 'Enter price'), prefix: '₹'),
        const SizedBox(height: 10),
        _chips(_price, const [('₹40', 40), ('₹50', 50), ('₹75', 75), ('₹100', 100), ('₹120', 120)]),
        const SizedBox(height: 20),
        _modeToggle(),
        const SizedBox(height: 20),
        _label(_p2w ? t('ग्राहक कितने का लेगा', 'Customer amount') : t('कितना वज़न चाहिए', 'Weight needed')),
        _field(_input, _p2w ? t('रकम डालें', 'Enter amount') : t('ग्राम डालें', 'Enter grams'),
            prefix: _p2w ? '₹' : '', suffix: _p2w ? '' : 'g'),
        const SizedBox(height: 10),
        _p2w
            ? _chips(_input, const [('₹10', 10), ('₹20', 20), ('₹50', 50), ('₹100', 100)])
            : _chips(_input, [
                ('50g', 50),
                ('100g', 100),
                (t('पाव', '1/4 kg'), 250),
                (t('आधा किलो', '1/2 kg'), 500),
                (t('1 किलो', '1 kg'), 1000),
              ]),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(anim), child: child)),
          child: KeyedSubtree(key: ValueKey(r?.big ?? 'empty'), child: _resultCard(r)),
        ),
        if (r != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _btn(t('सेव करें', 'Save'), Icons.bookmark_add_outlined, () => _saveHist(r))),
            const SizedBox(width: 10),
            Expanded(
                child: _btn(t('बिल में जोड़ें', 'Add to bill'), Icons.playlist_add_rounded,
                    () => _addToBill(r),
                    filled: true)),
          ]),
        ],
        const SizedBox(height: 10),
        _btn(t('साफ़ करें', 'Clear'), Icons.refresh_rounded, _clearCalc),
      ],
    );
  }

  Widget _modeToggle() {
    Widget side(bool p2w, bool rupeeFirst, String label) {
      final bool sel = _p2w == p2w;
      final Color c = sel ? p.onAccent : p.muted;
      final TextStyle ts = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c);
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _p2w = p2w;
              _input.clear();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
                color: sel ? p.accent : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(rupeeFirst ? '₹' : 'g', style: ts),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 18, color: c)),
                Text(rupeeFirst ? 'g' : '₹', style: ts),
              ]),
              Text(label, style: TextStyle(fontSize: 13, color: sel ? p.onAccent.withValues(alpha: 0.9) : p.muted)),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.line, width: 1),
          boxShadow: _sh),
      child: Row(children: [
        side(true, true, t('कीमत से वज़न', 'Price to Weight')),
        side(false, false, t('वज़न से कीमत', 'Weight to Price')),
      ]),
    );
  }

  Widget _resultCard(Res? r) {
    if (r == null) {
      return _card(Column(children: [
        Icon(Icons.touch_app_outlined, size: 30, color: p.muted),
        const SizedBox(height: 8),
        Text(t('कीमत और रकम डालिए, जवाब यहाँ दिखेगा', 'Enter the values, the answer shows here'),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.muted)),
      ]));
    }
    final Color on = p.onAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(24), boxShadow: _sh),
      child: Column(children: [
        Text(_p2w ? t('वज़न', 'Weight') : t('कुल कीमत', 'Amount'),
            style: TextStyle(fontSize: 15, color: on.withValues(alpha: 0.9))),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(r.big, style: TextStyle(fontSize: 64, fontWeight: FontWeight.w600, color: on)),
        ),
        Divider(height: 20, color: on.withValues(alpha: 0.3)),
        Text(r.sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: on)),
        if (r.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(r.note, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: on.withValues(alpha: 0.8))),
          ),
      ]),
    );
  }

  Widget _billPage() {
    final bool canAdd = (double.tryParse(_bPrice.text) ?? 0) > 0 && (double.tryParse(_bGrams.text) ?? 0) > 0;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(t('सामान जोड़ें', 'Add item')),
          _field(_bName, t('सामान का नाम (ज़रूरी नहीं)', 'Item name (optional)'), num: false, size: 20),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(_bPrice, t('₹/किलो', '₹/kg'), size: 22)),
            const SizedBox(width: 10),
            Expanded(child: _field(_bGrams, t('ग्राम', 'grams'), size: 22)),
          ]),
          const SizedBox(height: 10),
          _chips(_bGrams, [
            ('100g', 100),
            (t('पाव', '1/4 kg'), 250),
            (t('आधा किलो', '1/2 kg'), 500),
            (t('1 किलो', '1 kg'), 1000),
          ]),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: _btn(t('बिल में जोड़ें', 'Add to bill'), Icons.add_rounded, canAdd ? _addBillManual : null,
                  filled: true)),
        ])),
        const SizedBox(height: 16),
        if (_bill.isEmpty)
          _card(Center(child: Text(t('बिल अभी खाली है', 'Bill is empty'), style: TextStyle(fontSize: 15, color: p.muted))))
        else ...[
          ...List.generate(_bill.length, (i) {
            final BillItem it = _bill[i];
            final String nm = it.name.isEmpty ? '${t('सामान', 'Item')} ${_bill.length - i}' : it.name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _card(Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nm, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text)),
                    Text('${n(it.grams)}g × ₹${n(it.price)}/${t('किलो', 'kg')}',
                        style: TextStyle(fontSize: 13, color: p.muted)),
                  ]),
                ),
                Text('₹${m(it.amt)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.accentText)),
                IconButton(
                  onPressed: () => setState(() => _bill.removeAt(i)),
                  icon: Icon(Icons.close_rounded, color: p.muted),
                ),
              ])),
            );
          }),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(22), boxShadow: _sh),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(t('कुल', 'Total'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: p.onAccent)),
              Text('₹${m(_total)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: p.onAccent)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _btn(t('बिल कॉपी करें', 'Copy bill'), Icons.copy_rounded,
                    () => _copy(_billText, t('बिल कॉपी हो गया, WhatsApp में चिपकाइए', 'Copied, paste in WhatsApp')),
                    filled: true)),
            const SizedBox(width: 10),
            Expanded(
                child: _btn(t('बिल हटाएँ', 'Clear bill'), Icons.delete_outline_rounded,
                    () => setState(() => _bill.clear()))),
          ]),
        ],
      ],
    );
  }

  Widget _historyPage() {
    if (_hist.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.history_rounded, size: 48, color: p.muted),
          const SizedBox(height: 10),
          Text(t('अभी कोई हिस्ट्री नहीं', 'No history yet'), style: TextStyle(fontSize: 16, color: p.muted)),
          const SizedBox(height: 4),
          Text(t('कैलकुलेटर में "सेव करें" दबाइए', 'Tap "Save" in the calculator'),
              style: TextStyle(fontSize: 13, color: p.muted)),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        ..._hist.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _card(Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h.result, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: p.text)),
                    Text(h.rate, style: TextStyle(fontSize: 13, color: p.muted)),
                  ]),
                ),
                Text(h.time, style: TextStyle(fontSize: 13, color: p.muted)),
              ])),
            )),
        const SizedBox(height: 6),
        _btn(t('हिस्ट्री साफ़ करें', 'Clear history'), Icons.delete_outline_rounded, () => setState(() => _hist.clear())),
      ],
    );
  }

  Widget _helpPage() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _card(Column(children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              child: Icon(Icons.send_rounded, color: p.onAccent, size: 26),
            ),
            const SizedBox(height: 12),
            Text(t('सहायता चाहिए?', 'Need help?'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: p.text)),
            const SizedBox(height: 6),
            Text(t('कोई सवाल या सुझाव हो तो Telegram पर लिखिए', 'Message us on Telegram for any question or idea'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: p.muted)),
            const SizedBox(height: 12),
            Text(kTelegramUser, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: p.accentText)),
            const SizedBox(height: 14),
            SizedBox(
                width: double.infinity,
                child: _btn(t('Telegram खोलें', 'Open Telegram'), Icons.open_in_new_rounded, _openTelegram, filled: true)),
          ])),
          const SizedBox(height: 16),
          Center(child: Text('Kirana Kata  v1.0.0', style: TextStyle(fontSize: 12, color: p.muted))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [_calcPage(), _billPage(), _historyPage(), _helpPage()];
    Widget dest(IconData i, IconData si, String label) => NavigationDestination(
          icon: Icon(i, color: p.muted),
          selectedIcon: Icon(si, color: p.accentText),
          label: label,
        );
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(children: [
        Positioned.fill(child: _Pattern(color: p.text.withValues(alpha: _dark ? 0.05 : 0.05))),
        SafeArea(
          child: Column(children: [
            _header(),
            Expanded(child: pages[_tab]),
          ]),
        ),
      ]),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: p.surface,
            indicatorColor: p.accent.withValues(alpha: 0.2),
            labelTextStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.text)),
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) {
              FocusScope.of(context).unfocus();
              setState(() => _tab = i);
            },
            destinations: [
              dest(Icons.calculate_outlined, Icons.calculate_rounded, t('कैलकुलेटर', 'Calculator')),
              dest(Icons.receipt_long_outlined, Icons.receipt_long_rounded,
                  _bill.isEmpty ? t('बिल', 'Bill') : '${t('बिल', 'Bill')} (${_bill.length})'),
              dest(Icons.history_rounded, Icons.history_rounded, t('हिस्ट्री', 'History')),
              dest(Icons.support_agent_outlined, Icons.support_agent_rounded, t('सहायता', 'Help')),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Faint grocery-shop icons in the background.
class _Pattern extends StatelessWidget {
  final Color color;
  const _Pattern({required this.color});

  static const List<IconData> _icons = [
    Icons.shopping_basket_outlined,
    Icons.balance_outlined,
    Icons.grain,
    Icons.eco_outlined,
    Icons.storefront_outlined,
    Icons.rice_bowl_outlined,
    Icons.local_grocery_store_outlined,
    Icons.egg_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, box) {
        const double g = 88;
        final int cols = (box.maxWidth / g).ceil() + 1;
        final int rows = (box.maxHeight / g).ceil() + 1;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: (cols + 1) * g,
            maxHeight: rows * g,
            child: Column(
              children: List.generate(rows, (r) {
                return Row(
                  children: [
                    SizedBox(width: r.isOdd ? g / 2 : 0),
                    ...List.generate(cols, (c) {
                      return SizedBox(
                        width: g,
                        height: g,
                        child: Transform.rotate(
                          angle: -0.25,
                          child: Icon(_icons[(r * 3 + c) % _icons.length], size: 34, color: color),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ),
          ),
        );
      }),
    );
  }
}
