import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/diary_entry.dart';
import '../services/diary_storage.dart';
import 'edit_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await DiaryStorage.loadEntries();
    setState(() {
      _entries = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Vuoi eliminare "${entry.title}"?'),
        actions: [
          TextButton(
            child: const Text('Annulla'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DiaryStorage.deleteEntry(entry.id);
      _loadData();
    }
  }

  void _shareEntry(DiaryEntry entry) {
    final List<XFile> files = [];
    for (final p in entry.imagePaths) {
      if (File(p).existsSync()) files.add(XFile(p));
    }
    for (final v in entry.videoPaths) {
      if (File(v).existsSync()) files.add(XFile(v));
    }

    if (files.isNotEmpty) {
      Share.shareXFiles(files, text: entry.toShareableText());
    } else {
      Share.share(entry.toShareableText());
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _entries.where((e) {
      final q = _searchQuery.toLowerCase();
      return e.title.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q) ||
          (e.address?.toLowerCase().contains(q) ?? false) ||
          (e.phone?.toLowerCase().contains(q) ?? false) ||
          (e.email?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cerca appunti...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Nessun appunto nel Diario.\nPremi "+" per crearne uno!'
                            : 'Nessun risultato trovato.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditEntryScreen(entry: item),
                            ),
                          );
                          if (updated == true) _loadData();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(item.date),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (item.content.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  item.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              ],
                              // Info contatti badge
                              if ((item.phone?.isNotEmpty ?? false) ||
                                  (item.email?.isNotEmpty ?? false) ||
                                  (item.address?.isNotEmpty ?? false)) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (item.phone?.isNotEmpty ?? false)
                                      ActionChip(
                                        avatar: const Icon(Icons.phone, size: 16),
                                        label: Text(item.phone!),
                                        onPressed: () {
                                          launchUrl(Uri.parse('tel:${item.phone}'));
                                        },
                                      ),
                                    if (item.email?.isNotEmpty ?? false)
                                      ActionChip(
                                        avatar: const Icon(Icons.email, size: 16),
                                        label: Text(item.email!),
                                        onPressed: () {
                                          launchUrl(Uri.parse('mailto:${item.email}'));
                                        },
                                      ),
                                    if (item.address?.isNotEmpty ?? false)
                                      Chip(
                                        avatar: const Icon(Icons.location_on, size: 16),
                                        label: Text(item.address!),
                                      ),
                                  ],
                                ),
                              ],
                              // Anteprime Foto
                              if (item.imagePaths.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 60,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: item.imagePaths.length,
                                    itemBuilder: (ctx, i) {
                                      final p = item.imagePaths[i];
                                      return Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          image: DecorationImage(
                                            image: FileImage(File(p)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const Divider(height: 20),
                              // Azioni rapide
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.blueAccent),
                                    tooltip: 'Condividi',
                                    onPressed: () => _shareEntry(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    tooltip: 'Elimina',
                                    onPressed: () => _deleteEntry(item),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuovo appunto'),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditEntryScreen(),
            ),
          );
          if (res == true) _loadData();
        },
      ),
    );
  }
}
