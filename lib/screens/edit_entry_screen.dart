import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../services/diary_storage.dart';

class EditEntryScreen extends StatefulWidget {
  final DiaryEntry? entry;

  const EditEntryScreen({super.key, this.entry});

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];
  List<String> _videoPaths = [];

  bool _showContactFields = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _contentController = TextEditingController(text: e?.content ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _imagePaths = List.from(e?.imagePaths ?? []);
    _videoPaths = List.from(e?.videoPaths ?? []);

    if ((e?.address?.isNotEmpty ?? false) ||
        (e?.phone?.isNotEmpty ?? false) ||
        (e?.email?.isNotEmpty ?? false)) {
      _showContactFields = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imagePaths.add(photo.path);
      });
    }
  }

  Future<void> _pickGalleryImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      setState(() {
        _videoPaths.add(video.path);
      });
    }
  }

  Future<void> _pickGalleryVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videoPaths.add(video.path);
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _imagePaths.isEmpty && _videoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci almeno del testo o una foto/video')),
      );
      return;
    }

    final entry = DiaryEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      title: title.isEmpty ? 'Senza titolo' : title,
      content: content,
      date: widget.entry?.date ?? DateTime.now(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      imagePaths: _imagePaths,
      videoPaths: _videoPaths,
    );

    await DiaryStorage.saveOrUpdateEntry(entry);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _shareEntry() {
    final buffer = StringBuffer();
    if (_titleController.text.isNotEmpty) {
      buffer.writeln("=== ${_titleController.text} ===");
    }
    if (_contentController.text.isNotEmpty) {
      buffer.writeln(_contentController.text);
    }
    if (_addressController.text.isNotEmpty) {
      buffer.writeln("\nIndirizzo: ${_addressController.text}");
    }
    if (_phoneController.text.isNotEmpty) {
      buffer.writeln("Telefono: ${_phoneController.text}");
    }
    if (_emailController.text.isNotEmpty) {
      buffer.writeln("Email: ${_emailController.text}");
    }

    final List<XFile> files = [];
    for (final p in _imagePaths) {
      files.add(XFile(p));
    }
    for (final v in _videoPaths) {
      files.add(XFile(v));
    }

    if (files.isNotEmpty) {
      Share.shareXFiles(files, text: buffer.toString());
    } else {
      Share.share(buffer.toString());
    }
  }

  Future<void> _copyContent() async {
    final text = _contentController.text;
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testo copiato negli appunti!')),
        );
      }
    }
  }

  Future<void> _pasteContent() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final current = _contentController.text;
      final selection = _contentController.selection;
      if (selection.isValid && selection.start >= 0 && selection.end >= selection.start) {
        final newText = current.replaceRange(selection.start, selection.end, data.text!);
        _contentController.text = newText;
      } else {
        _contentController.text = current + data.text!;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Nuova Nota' : 'Modifica Nota'),
        actions: [
          IconButton(
            tooltip: 'Condividi',
            icon: const Icon(Icons.share),
            onPressed: _shareEntry,
          ),
          IconButton(
            tooltip: 'Salva',
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titolo
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Titolo...',
                border: InputBorder.none,
              ),
            ),
            const Divider(),

            // Toolbar selezione / copia / incolla
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copia tutto il testo',
                  onPressed: _copyContent,
                ),
                IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Incolla dagli appunti',
                  onPressed: _pasteContent,
                ),
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Seleziona tutto il testo',
                  onPressed: () {
                    _contentController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _contentController.text.length,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Cancella testo',
                  onPressed: () {
                    _contentController.clear();
                    setState(() {});
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(_showContactFields ? Icons.keyboard_arrow_up : Icons.contact_mail),
                  label: Text(_showContactFields ? 'Nascondi dati' : 'Aggiungi dati'),
                  onPressed: () {
                    setState(() {
                      _showContactFields = !_showContactFields;
                    });
                  },
                ),
              ],
            ),
            const Divider(),

            // Campi contatti/dati opzionali
            if (_showContactFields) ...[
              Card(
                color: Colors.blueGrey.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Indirizzo',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefono',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Contenuto Principale
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 8,
              enableInteractiveSelection: true, // Selezione, copia e incolla nativi abilitati
              decoration: const InputDecoration(
                hintText: 'Scrivi qui i tuoi appunti...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),

            // Pulsanti Foto e Video
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.camera_alt),
                  label: const Text('Scatta Foto'),
                  onPressed: _takePhoto,
                ),
                ActionChip(
                  avatar: const Icon(Icons.photo_library),
                  label: const Text('Galleria Foto'),
                  onPressed: _pickGalleryImage,
                ),
                ActionChip(
                  avatar: const Icon(Icons.videocam),
                  label: const Text('Registra Video'),
                  onPressed: _recordVideo,
                ),
                ActionChip(
                  avatar: const Icon(Icons.video_library),
                  label: const Text('Galleria Video'),
                  onPressed: _pickGalleryVideo,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Galleria Immagini caricate
            if (_imagePaths.isNotEmpty) ...[
              const Text('Foto allegate:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    final path = _imagePaths[index];
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _imagePaths.removeAt(index);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Lista Video caricati
            if (_videoPaths.isNotEmpty) ...[
              const Text('Video allegati:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: _videoPaths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final path = entry.value;
                  final fileName = path.split(Platform.pathSeparator).last;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.movie, color: Colors.indigo, size: 36),
                    title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _videoPaths.removeAt(index);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
