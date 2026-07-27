import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/deneme_provider.dart';
import '../../models/deneme_kaydi.dart';

class KayitlarTab extends StatefulWidget {
  const KayitlarTab({super.key});
  @override
  State<KayitlarTab> createState() => _KayitlarTabState();
}

class _KayitlarTabState extends State<KayitlarTab> {
  final _adCtrl = TextEditingController();
  final _sayDCtrl = TextEditingController();
  final _sayYCtrl = TextEditingController();
  final _sozDCtrl = TextEditingController();
  final _sozYCtrl = TextEditingController();
  final _notCtrl = TextEditingController();
  bool _formVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<DenemeProvider>(context, listen: false);
      _adCtrl.text = prov.onerilAd();
    });
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _sayDCtrl.dispose();
    _sayYCtrl.dispose();
    _sozDCtrl.dispose();
    _sozYCtrl.dispose();
    _notCtrl.dispose();
    super.dispose();
  }

  void _kaydet() {
    final ad = _adCtrl.text.trim().isEmpty ? 'Deneme' : _adCtrl.text.trim();
    final sayD = int.tryParse(_sayDCtrl.text) ?? 0;
    final sayY = int.tryParse(_sayYCtrl.text) ?? 0;
    final sozD = int.tryParse(_sozDCtrl.text) ?? 0;
    final sozY = int.tryParse(_sozYCtrl.text) ?? 0;
    if (sayD + sayY > 50 || sozD + sozY > 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bölümdeki toplam soru sayısı 50\'yi aşamaz!'),
          backgroundColor: Color(0xFFFF4D4D)));
      return;
    }
    final kayit = DenemeKaydi(
      id: DateTime.now().toIso8601String(),
      ad: ad,
      tarih: DateTime.now(),
      sayisalDogru: sayD,
      sayisalYanlis: sayY,
      sozelDogru: sozD,
      sozelYanlis: sozY,
      notlar: _notCtrl.text.trim().isEmpty ? null : _notCtrl.text.trim(),
    );
    Provider.of<DenemeProvider>(context, listen: false).denemeleriKaydet(kayit);
    setState(() {
      _formVisible = false;
    });
    _sayDCtrl.clear();
    _sayYCtrl.clear();
    _sozDCtrl.clear();
    _sozYCtrl.clear();
    _notCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<DenemeProvider>(context, listen: false);
      _adCtrl.text = prov.onerilAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final prov = Provider.of<DenemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Deneme Kayıtları',
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.bold, color: tc)),
            Text('${prov.denemeler.length} deneme kaydedildi',
                style: GoogleFonts.inter(
                    fontSize: 12, color: tc.withValues(alpha: 0.4))),
          ]),
          GestureDetector(
            onTap: () => setState(() => _formVisible = !_formVisible),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: _formVisible
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF7F5AF0), Color(0xFF6246DB)]),
                color:
                    _formVisible ? Colors.white.withValues(alpha: 0.07) : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _formVisible
                        ? tc.withValues(alpha: 0.2)
                        : Colors.transparent),
                boxShadow: _formVisible
                    ? []
                    : [
                        BoxShadow(
                            color:
                                const Color(0xFF7F5AF0).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_formVisible ? Icons.close : Icons.add,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(_formVisible ? 'Vazgeç' : 'Yeni Deneme',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildForm(tc, isDark),
          crossFadeState: _formVisible
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        if (prov.denemeler.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(children: [
                Icon(Icons.assignment_outlined,
                    size: 56, color: tc.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text('Henüz deneme yok',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: tc.withValues(alpha: 0.35))),
                const SizedBox(height: 6),
                Text('Simülatörü kullan veya Yeni Deneme ekle',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: tc.withValues(alpha: 0.25))),
              ]),
            ),
          )
        else
          ...prov.denemeler.map((d) => _DenemeKayitCard(
              kayit: d, onSil: () => prov.denemeleriSil(d.id))),
      ]),
    );
  }

  Widget _buildForm(Color tc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF7F5AF0).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7F5AF0).withValues(alpha: 0.08),
              blurRadius: 20)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Deneme Bilgileri',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 15, color: tc)),
        const SizedBox(height: 14),
        _field(_adCtrl, 'Deneme Adı (ör. DGS Deneme 4)', Icons.label_outline,
            tc, isDark),
        const SizedBox(height: 14),
        Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Color(0xFF00B4D8), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Sayısal',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF00B4D8))),
        ]),
        const SizedBox(height: 8),
        _dyRow(_sayDCtrl, _sayYCtrl, const Color(0xFF00B4D8), tc, isDark),
        const SizedBox(height: 14),
        Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFB800), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Sözel',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFFFFB800))),
        ]),
        const SizedBox(height: 8),
        _dyRow(_sozDCtrl, _sozYCtrl, const Color(0xFFFFB800), tc, isDark),
        const SizedBox(height: 14),
        _NetOnizleme(
            sayDCtrl: _sayDCtrl,
            sayYCtrl: _sayYCtrl,
            sozDCtrl: _sozDCtrl,
            sozYCtrl: _sozYCtrl),
        const SizedBox(height: 14),
        _field(_notCtrl, 'Not (opsiyonel)', Icons.note_outlined, tc, isDark),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _kaydet,
            icon: const Icon(Icons.save_rounded),
            label: Text('Kaydet',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F5AF0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      Color tc, bool isDark) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(color: tc, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: tc.withValues(alpha: 0.3), fontSize: 13),
        prefixIcon: Icon(icon, color: tc.withValues(alpha: 0.4), size: 20),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7F5AF0), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dyRow(TextEditingController dCtrl, TextEditingController yCtrl,
      Color color, Color tc, bool isDark) {
    Widget numField(TextEditingController ctrl, String label) {
      return Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: color.withValues(alpha: 0.85))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: tc, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: color.withValues(alpha: 0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ]));
    }

    return Row(children: [
      numField(dCtrl, 'Doğru'),
      const SizedBox(width: 12),
      numField(yCtrl, 'Yanlış'),
    ]);
  }
}

class _NetOnizleme extends StatefulWidget {
  final TextEditingController sayDCtrl, sayYCtrl, sozDCtrl, sozYCtrl;
  const _NetOnizleme(
      {required this.sayDCtrl,
      required this.sayYCtrl,
      required this.sozDCtrl,
      required this.sozYCtrl});
  @override
  State<_NetOnizleme> createState() => _NetOnizlemeState();
}

class _NetOnizlemeState extends State<_NetOnizleme> {
  @override
  void initState() {
    super.initState();
    widget.sayDCtrl.addListener(() => setState(() {}));
    widget.sayYCtrl.addListener(() => setState(() {}));
    widget.sozDCtrl.addListener(() => setState(() {}));
    widget.sozYCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final sayD = int.tryParse(widget.sayDCtrl.text) ?? 0;
    final sayY = int.tryParse(widget.sayYCtrl.text) ?? 0;
    final sozD = int.tryParse(widget.sozDCtrl.text) ?? 0;
    final sozY = int.tryParse(widget.sozYCtrl.text) ?? 0;
    final sayNet = sayD - sayY / 4;
    final sozNet = sozD - sozY / 4;
    final topNet = sayNet + sozNet;
    final puan = 120 + topNet * 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF7F5AF0).withValues(alpha: 0.1),
          const Color(0xFF00B4D8).withValues(alpha: 0.1)
        ]),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF7F5AF0).withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _netItem(
            'Say. Net', sayNet.toStringAsFixed(1), const Color(0xFF00B4D8)),
        _netItem(
            'Söz. Net', sozNet.toStringAsFixed(1), const Color(0xFFFFB800)),
        _netItem('Toplam', topNet.toStringAsFixed(1), const Color(0xFF2CB67D)),
        _netItem('Puan', puan.toStringAsFixed(0), const Color(0xFF7F5AF0)),
      ]),
    );
  }

  Widget _netItem(String label, String val, Color c) => Column(children: [
        Text(val,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 17, color: c)),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: c.withValues(alpha: 0.7))),
      ]);
}

class _DenemeKayitCard extends StatelessWidget {
  final DenemeKaydi kayit;
  final VoidCallback onSil;
  const _DenemeKayitCard({required this.kayit, required this.onSil});

  @override
  Widget build(BuildContext context) {
    final tc = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final netColor = kayit.toplamNet >= 50
        ? const Color(0xFF2CB67D)
        : kayit.toplamNet >= 25
            ? const Color(0xFFFFB800)
            : const Color(0xFFFF4D4D);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: netColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: netColor.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [netColor.withValues(alpha: 0.8), netColor]),
                shape: BoxShape.circle),
            child: const Icon(Icons.assignment_turned_in,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(kayit.ad,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 15, color: tc)),
                Text(
                    '${kayit.tarih.day}.${kayit.tarih.month}.${kayit.tarih.year}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: tc.withValues(alpha: 0.4))),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${kayit.toplamNet.toStringAsFixed(1)} Net',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: netColor)),
            Text('~${kayit.tahminiPuan.toStringAsFixed(0)} Puan',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF7F5AF0),
                    fontWeight: FontWeight.bold)),
          ]),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _bolumChip('Sayısal', kayit.sayisalDogru, kayit.sayisalYanlis,
              kayit.sayisalNet, const Color(0xFF00B4D8)),
          const SizedBox(width: 10),
          _bolumChip('Sözel', kayit.sozelDogru, kayit.sozelYanlis,
              kayit.sozelNet, const Color(0xFFFFB800)),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        title: const Text('Sil'),
                        content: Text('${kayit.ad} silinsin mi?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('İptal')),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onSil();
                              },
                              child: const Text('Sil',
                                  style: TextStyle(color: Color(0xFFFF4D4D)))),
                        ],
                      ));
            },
            icon: Icon(Icons.delete_outline,
                color: tc.withValues(alpha: 0.35), size: 20),
          ),
        ]),
        if (kayit.notlar != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: tc.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10)),
            child: Text('💬 ${kayit.notlar}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: tc.withValues(alpha: 0.55))),
          ),
        ],
      ]),
    );
  }

  Widget _bolumChip(String ad, int d, int y, double net, Color color) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ad,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('D:$d  Y:$y',
              style: GoogleFonts.inter(
                  fontSize: 11, color: color.withValues(alpha: 0.8))),
          Text('${net.toStringAsFixed(1)}N',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    ));
  }
}
