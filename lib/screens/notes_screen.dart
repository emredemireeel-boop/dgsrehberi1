import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/note_item.dart';
import '../models/note_image_item.dart';
import '../providers/plan_provider.dart';
import '../providers/note_images_provider.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Note color palette
const _noteColors = [
  Color(0xFF7F5AF0), // purple
  Color(0xFF2CB67D), // green
  Color(0xFFFF6B6B), // red
  Color(0xFFFF9F1C), // orange
  Color(0xFF00B4D8), // blue
  Color(0xFFE53170), // pink
  Color(0xFF43BCCD), // teal
  Color(0xFF94A1B2), // gray
];

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late TabController _tabCtrl;
  late AnimationController _fabCtrl;
  late Animation<double> _fabAnim;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {});
    });
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fabAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOutBack));
    _fabCtrl.forward();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Consumer<PlanProvider>(
      builder: (context, planProv, _) {
        final allNotes = planProv.sortedNotes;
        final filtered = _searchQuery.isEmpty
            ? allNotes
            : allNotes
                .where((n) =>
                    n.title
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    n.content
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList();

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F0E17) : const Color(0xFFF7F7F8),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SEKMELER ──────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF7F5AF0), Color(0xFF6246DB)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: textColor.withValues(alpha: 0.4),
                    labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Yazılı Notlar'),
                      Tab(text: 'Görsel Notlar'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── CONTENT ───────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      // TAB 1 - YAZILI NOTLAR
                      Column(
                        children: [
                          _NotesHeader(
                            isDark: isDark,
                            textColor: textColor,
                            noteCount: allNotes.length,
                            searchCtrl: _searchCtrl,
                            onSearch: (q) => setState(() => _searchQuery = q),
                          ),
                          Expanded(
                            child: filtered.isEmpty
                                ? _EmptyNotesState(
                                    isDark: isDark,
                                    textColor: textColor,
                                    isEmpty: allNotes.isEmpty,
                                  )
                                : _NotesGrid(
                                    notes: filtered,
                                    isDark: isDark,
                                    planProv: planProv,
                                  ),
                          ),
                        ],
                      ),
                      // TAB 2 - GÖRSEL NOTLAR
                      const _ImageNotesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabAnim,
            child: FloatingActionButton.extended(
              onPressed: () {
                if (_tabCtrl.index == 0) {
                  _showAddNoteSheet(context, planProv, isDark);
                } else {
                  _showImagePickerOptions(context,
                      Provider.of<NoteImagesProvider>(context, listen: false));
                }
              },
              backgroundColor: const Color(0xFF7F5AF0),
              foregroundColor: Colors.white,
              icon: Icon(_tabCtrl.index == 0
                  ? Icons.add_rounded
                  : Icons.add_photo_alternate_rounded),
              label: Text(_tabCtrl.index == 0 ? 'Yeni Not' : 'Foto Ekle',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              elevation: 8,
            ),
          ),
          bottomNavigationBar: const SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: BannerAdWidget(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showImagePickerOptions(
      BuildContext context, NoteImagesProvider provider) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF7F5AF0)),
              title: Text('Kameradan Çek',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, provider);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF2CB67D)),
              title: Text('Galeriden Seç',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, NoteImagesProvider prov) async {
    try {
      if (Platform.isAndroid) {
        if (source == ImageSource.camera) {
          final camStatus = await Permission.camera.request();
          if (camStatus.isPermanentlyDenied) return;
        } else {
          // Galeri (SDK 33+ için photos, altı için storage)
          final vinfo = await Process.run('getprop', ['ro.build.version.sdk']);
          final sdk = int.tryParse(vinfo.stdout.toString().trim()) ?? 30;
          if (sdk >= 33) {
            final pStatus = await Permission.photos.request();
            if (pStatus.isPermanentlyDenied) return;
          } else {
            final sStatus = await Permission.storage.request();
            if (sStatus.isPermanentlyDenied) return;
          }
        }
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        final targetDir = await prov.getNoteImagesDirectoryPath();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${p.basename(picked.path)}';
        await File(picked.path).copy(p.join(targetDir, fileName));
        await prov.loadItems();
      }
    } catch (e) {
      debugPrint('Foto seçilemedi: $e');
    }
  }

  void _showAddNoteSheet(
      BuildContext context, PlanProvider planProv, bool isDark) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    int selectedColor = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final color = _noteColors[selectedColor];
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1825) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with color strip
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Yeni Not',
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF16161A))),
                ],
              ),
              const SizedBox(height: 16),

              // Color picker
              Row(
                children: List.generate(_noteColors.length, (i) {
                  final c = _noteColors[i];
                  final sel = i == selectedColor;
                  return GestureDetector(
                    onTap: () => setSheet(() => selectedColor = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      width: sel ? 30 : 24,
                      height: sel ? 30 : 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(
                                color: Colors.white,
                                width: 2,
                              )
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.4),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: titleCtrl,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF16161A),
                ),
                decoration: InputDecoration(
                  hintText: 'Başlık (opsiyonel)',
                  hintStyle: GoogleFonts.inter(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.3),
                      fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Container(
                  height: 1,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08)),
              const SizedBox(height: 12),

              // Content
              TextField(
                controller: contentCtrl,
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white : const Color(0xFF16161A),
                    fontSize: 14),
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Notunu buraya yaz...',
                  hintStyle: GoogleFonts.inter(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.3),
                      fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (contentCtrl.text.trim().isEmpty &&
                          titleCtrl.text.trim().isEmpty) {
                        return;
                      }
                      planProv.addNote(NoteItem(
                        id: DateTime.now().toIso8601String(),
                        title: titleCtrl.text.trim(),
                        content: contentCtrl.text.trim(),
                        createdAt: DateTime.now(),
                        colorIndex: selectedColor,
                      ));
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Kaydet',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── HEADER ─────────────────────────────────────────────────────────────────────
class _NotesHeader extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final int noteCount;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  const _NotesHeader({
    required this.isDark,
    required this.textColor,
    required this.noteCount,
    required this.searchCtrl,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: isDark ? const Color(0xFF0D0B15) : const Color(0xFFFAFAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notlarım',
                      style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  Text('$noteCount not kaydedildi',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.45))),
                ],
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF7F5AF0).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.sticky_note_2_outlined,
                    color: Color(0xFF7F5AF0), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              style: GoogleFonts.inter(color: textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Notlarda ara...',
                hintStyle: GoogleFonts.inter(
                    color: textColor.withValues(alpha: 0.35), fontSize: 13),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search_rounded,
                    color: textColor.withValues(alpha: 0.35), size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          searchCtrl.clear();
                          onSearch('');
                        },
                        child: Icon(Icons.close_rounded,
                            color: textColor.withValues(alpha: 0.4), size: 16),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── NOTES GRID ─────────────────────────────────────────────────────────────────
class _NotesGrid extends StatelessWidget {
  final List<NoteItem> notes;
  final bool isDark;
  final PlanProvider planProv;

  const _NotesGrid(
      {required this.notes, required this.isDark, required this.planProv});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: notes.length,
      itemBuilder: (ctx, i) => _NoteCard(
        note: notes[i],
        isDark: isDark,
        planProv: planProv,
      ),
    );
  }
}

// ── NOTE CARD ──────────────────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final NoteItem note;
  final bool isDark;
  final PlanProvider planProv;

  const _NoteCard(
      {required this.note, required this.isDark, required this.planProv});

  @override
  Widget build(BuildContext context) {
    final color = _noteColors[note.colorIndex % _noteColors.length];
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final cardBg = isDark ? const Color(0xFF13111C) : Colors.white;

    return GestureDetector(
      onLongPress: () => _showOptions(context, color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: note.isPinned ? 0.2 : 0.08),
                blurRadius: note.isPinned ? 20 : 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // Top color strip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),
            // Pinned indicator
            if (note.isPinned)
              Positioned(
                top: 10,
                right: 12,
                child: Icon(Icons.push_pin_rounded, color: color, size: 14),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.title.isNotEmpty) ...[
                    Text(
                      note.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Expanded(
                    child: Text(
                      note.content,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.65),
                        height: 1.5,
                      ),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _fmtDate(note.createdAt),
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(dt.year, dt.month, dt.day);
    if (noteDay == today) return 'Bugün';
    if (noteDay == today.subtract(const Duration(days: 1))) return 'Dün';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showOptions(BuildContext context, Color color) {
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
            _OptionTile(
              icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              label: note.isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle',
              color: color,
              onTap: () {
                planProv.togglePin(note.id);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Notu Sil',
              color: Colors.red,
              onTap: () {
                planProv.removeNote(note.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF16161A))),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: color.withValues(alpha: 0.04),
    );
  }
}

// ── EMPTY STATE ────────────────────────────────────────────────────────────────
class _EmptyNotesState extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final bool isEmpty;

  const _EmptyNotesState(
      {required this.isDark, required this.textColor, required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7F5AF0).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sticky_note_2_outlined,
                color: Color(0xFF7F5AF0), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty ? 'Henüz not yok' : 'Sonuç bulunamadı',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 6),
          Text(
            isEmpty
                ? 'Sağ alttaki + ile not ekleyebilirsin'
                : 'Farklı bir arama deneyin',
            style: GoogleFonts.inter(
                fontSize: 13, color: textColor.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}

// ── GÖRSEL NOTLAR TABI VE İLGİLİ SINIFLAR ──────────────────────────────────────

class _ImageNotesTab extends StatelessWidget {
  const _ImageNotesTab();

  @override
  Widget build(BuildContext context) {
    final tc = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Consumer<NoteImagesProvider>(
      builder: (context, provider, _) {
        final items = provider.items;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2CB67D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      size: 56,
                      color: const Color(0xFF2CB67D).withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 20),
                Text('Henüz görsel notun yok',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: tc,
                    )),
                const SizedBox(height: 8),
                Text(
                    'Aşağıdaki butondan kamera veya galeriyle\nçözemediğin veya önemli gördüğün\nsoruları ekleyebilirsin.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: tc.withValues(alpha: 0.4))),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final file = File(item.filePath);

            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => _ImageNoteDialog(
                    item: item,
                    provider: provider,
                    onClose: () => Navigator.pop(ctx),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: item.tag.isNotEmpty
                        ? const Color(0xFF2CB67D).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06),
                    width: item.tag.isNotEmpty ? 2.0 : 1.0,
                  ),
                  image: DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    if (item.tag.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2CB67D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.tag,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ImageNoteDialog extends StatefulWidget {
  final NoteImageItem item;
  final NoteImagesProvider provider;
  final VoidCallback onClose;

  const _ImageNoteDialog(
      {required this.item, required this.provider, required this.onClose});

  @override
  State<_ImageNoteDialog> createState() => _ImageNoteDialogState();
}

class _ImageNoteDialogState extends State<_ImageNoteDialog> {
  late String _tag;
  static const _tags = ['Matematik', 'Türkçe', 'Önemli', 'Formül', 'Soru', ''];

  @override
  void initState() {
    super.initState();
    _tag = widget.item.tag;
  }

  void _setTag(String t) {
    setState(() => _tag = t == _tag ? '' : t);
    final updated = NoteImageItem(
      filePath: widget.item.filePath,
      tag: _tag,
      createdAt: widget.item.createdAt,
    );
    widget.provider.updateItem(updated);
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.item.filePath);
    final tc = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF2CB67D).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Etiket Seç',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: tc)),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            widget.provider.deleteItem(widget.item);
                            widget.onClose();
                          },
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.where((t) => t.isNotEmpty).map((t) {
                        final sel = t == _tag;
                        return GestureDetector(
                          onTap: () => _setTag(t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF2CB67D)
                                  : const Color(0xFF2CB67D)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF2CB67D)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(t,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : const Color(0xFF2CB67D))),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}
