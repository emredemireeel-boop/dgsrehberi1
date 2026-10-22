import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../providers/questions_provider.dart';
import '../models/question_item.dart';
import '../widgets/banner_ad_widget.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});

  void _showImageDialog(BuildContext context, QuestionItem initialItem,
      QuestionsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _QuestionDialogContent(
        item: initialItem,
        provider: provider,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuestionsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE53170), Color(0xFFFFB800)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.question_mark_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Soru Galerim',
                            style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        Text('Çözemediğin soruları takip et',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grid
            Expanded(
              child: provider.questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined,
                              size: 64,
                              color: textColor.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text('Henüz çözemediğin bir soru yok.',
                              style: GoogleFonts.inter(
                                  color: textColor.withValues(alpha: 0.5),
                                  fontSize: 15)),
                          const SizedBox(height: 8),
                          Text('Foto eklemek için + butonunu kullan',
                              style: GoogleFonts.inter(
                                  color: textColor.withValues(alpha: 0.35),
                                  fontSize: 12)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: provider.questions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final item = provider.questions[index];
                        final file = File(item.filePath);
                        final bool isDue = item.isDueToday();

                        return GestureDetector(
                          onTap: () =>
                              _showImageDialog(context, item, provider),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDue
                                    ? Colors.amber
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05)),
                                width: isDue ? 2.5 : 1,
                              ),
                              image: DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                if (isDue)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text('BUGÜN',
                                          style: GoogleFonts.outfit(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                if (item.category.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: item.category == 'Sayısal'
                                              ? Colors.blue
                                              : Colors.purple,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(item.category,
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.zoom_in,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // ── Banner Reklam (Alt) ────────────────────────────────────────────
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: BannerAdWidget(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE53170),
        foregroundColor: Colors.white,
        onPressed: () => _showPickerSheet(context, provider),
        child: const Icon(Icons.add_photo_alternate_rounded),
      ),
    );
  }

  void _showPickerSheet(BuildContext context, QuestionsProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1825) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Soru Ekle',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF16161A))),
            const SizedBox(height: 6),
            Text('Kamera\'dan çek veya galeriden seç',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.45))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _PickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: const Color(0xFF7F5AF0),
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _pickImageWithPermission(
                          context, provider, ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: const Color(0xFFE53170),
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _pickImageWithPermission(
                          context, provider, ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// İzin kontrol ederek resim seçer.
  Future<void> _pickImageWithPermission(BuildContext context,
      QuestionsProvider provider, ImageSource source) async {
    final Permission permission = source == ImageSource.camera
        ? Permission.camera
        : (Platform.isAndroid
            ? (await _androidVersion() >= 33
                ? Permission.photos
                : Permission.storage)
            : Permission.photos);

    final status = await permission.status;
    if (!context.mounted) return;

    if (status.isGranted) {
      await _pickImage(context, provider, source);
    } else if (status.isDenied) {
      final result = await permission.request();
      if (!context.mounted) return;
      if (result.isGranted) {
        await _pickImage(context, provider, source);
      } else {
        _showPermissionDenied(context, source);
      }
    } else if (status.isPermanentlyDenied) {
      _showOpenSettings(context, source);
    } else {
      // restricted veya limited → direkt dene
      await _pickImage(context, provider, source);
    }
  }

  Future<int> _androidVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      // Android SDK version
      return int.tryParse(Platform.operatingSystemVersion
              .replaceAll(RegExp(r'[^0-9]'), '')
              .substring(0, 2)) ??
          0;
    } catch (_) {
      return 30; // Bilinmiyorsa güvenli taraf
    }
  }

  void _showPermissionDenied(BuildContext context, ImageSource source) {
    final label = source == ImageSource.camera ? 'kamera' : 'galeri';
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.block, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text('$label iznine ihtiyaç var',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showOpenSettings(BuildContext context, ImageSource source) {
    final label = source == ImageSource.camera ? 'Kamera' : 'Galeri';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1825) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              Text('$label İzni Gerekli',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF16161A))),
              const SizedBox(height: 8),
              Text(
                '$label erişimi kalıcı olarak reddedildi.\nAyarlardan izin ver.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.55),
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text('Vazgeç',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.6))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE53170), Color(0xFFFF6B6B)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text('Ayarları Aç',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, QuestionsProvider provider,
      ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;

      final questionsDir = await provider.getQuestionsDirectoryPath();
      final fileName = 'soru_${DateTime.now().millisecondsSinceEpoch}.png';
      final destPath = p.join(questionsDir, fileName);
      await File(picked.path).copy(destPath);
      await provider.loadQuestions();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Soru başarıyla eklendi! ✅',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF2CB67D),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata oluştu: $e',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}

class _QuestionDialogContent extends StatefulWidget {
  final QuestionItem item;
  final QuestionsProvider provider;
  final VoidCallback onClose;

  const _QuestionDialogContent({
    required this.item,
    required this.provider,
    required this.onClose,
  });

  @override
  State<_QuestionDialogContent> createState() => _QuestionDialogContentState();
}

class _QuestionDialogContentState extends State<_QuestionDialogContent> {
  late String _category;
  late List<int> _reminderDays;

  @override
  void initState() {
    super.initState();
    _category = widget.item.category;
    _reminderDays = List.from(widget.item.reminderDays);
  }

  void _saveChanges() async {
    final newItem = QuestionItem(
      filePath: widget.item.filePath,
      category: _category,
      reminderDays: _reminderDays,
      createdAt: widget.item.createdAt,
    );
    await widget.provider.updateQuestion(newItem);
  }

  void _toggleDay(int day) {
    setState(() {
      if (_reminderDays.contains(day)) {
        _reminderDays.remove(day);
      } else {
        _reminderDays.add(day);
      }
    });
    _saveChanges();
  }

  void _setCategory(String cat) {
    setState(() => _category = cat);
    _saveChanges();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.item.filePath);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final screenH = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resim
          SizedBox(
            height: screenH * 0.45,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Meta Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: textColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ders',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Sayısal'),
                      selected: _category == 'Sayısal',
                      onSelected: (_) => _setCategory('Sayısal'),
                      selectedColor: Colors.blue.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Sözel'),
                      selected: _category == 'Sözel',
                      onSelected: (_) => _setCategory('Sözel'),
                      selectedColor: Colors.purple.withValues(alpha: 0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Hatırlatma',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [3, 7, 21].map((day) {
                    final isSelected = _reminderDays.contains(day);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('$day. Gün'),
                        selected: isSelected,
                        onSelected: (_) => _toggleDay(day),
                        selectedColor: Colors.amber.withValues(alpha: 0.3),
                        checkmarkColor: isSelected ? Colors.amber[800] : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: Text('Soruyu Sil',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      widget.provider.deleteQuestion(widget.item);
                      widget.onClose();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Kapat butonu
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            label:
                Text('Kapat', style: GoogleFonts.inter(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// ── PICKER OPTION BUTTON ──────────────────────────────────────────────────────
class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
