import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Note {
  final String title;
  final String text;

  Note({required this.title, required this.text});

  Map<String, dynamic> toJson() => {
        'title': title,
        'text': text,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        title: json['title'] as String,
        text: json['text'] as String,
      );
}

void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
    appWindow.minSize = const Size(700, 400);
    appWindow.size = const Size(1000, 700);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Virazx Quick Note',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotesJson = prefs.getString('notes_list');

      List<Note> loadedNotes = [];
      if (savedNotesJson != null && savedNotesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedNotesJson);
        loadedNotes = decoded
            .map((json) => Note.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final savedText = prefs.getString('current_text');
      if (savedText != null) {
        _textController.text = savedText;
      }

      if (mounted) {
        setState(() {
          _notes = loadedNotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Load error: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCurrentText() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_text', _textController.text);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Save error: $e');
      }
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notes.map((note) => note.toJson()).toList());
      await prefs.setString('notes_list', encoded);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Save error: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2B2B2B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSaveDialog() async {
    _titleController.clear();
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text(
          'Name your note',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        content: TextField(
          controller: _titleController,
          autofocus: true,
          style: const TextStyle(color: Color(0xFFE0E0E0)),
          decoration: const InputDecoration(
            hintText: 'Enter name...',
            hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFB6C1)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF555555)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  _notes.add(Note(
                    title: title,
                    text: _textController.text,
                  ));
                });
                await _saveNotes();
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Note saved!');
                }
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFFFFB6C1)),
            ),
          ),
        ],
      ),
    );
  }

  void _loadNote(Note note) {
    setState(() {
      _textController.text = note.text;
    });
    _saveCurrentText();
    _showSnackBar('Note loaded!');
  }

  Future<void> _deleteNote(int index) async {
    setState(() {
      _notes.removeAt(index);
    });
    await _saveNotes();
    _showSnackBar('Note deleted!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: WindowBorder(
        color: const Color(0xFFFFB6C1),
        width: 1,
        child: Column(
          children: [
            WindowTitleBarBox(
              child: Container(
                color: const Color(0xFF1E1E1E),
                child: Row(
                  children: [
                    Expanded(
                      child: MoveWindow(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Virazx Quick Note',
                                  style: TextStyle(
                                    color: Color(0xFFFFB6C1),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const WindowButtons(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFB6C1),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            color: const Color(0xFF2B2B2B),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3D3D3D),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        onPressed: _showSaveDialog,
                                        icon: const Icon(Icons.arrow_downward,
                                            size: 20),
                                        color: const Color(0xFFFFB6C1),
                                        tooltip: 'Save note',
                                        splashRadius: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 8),
                                    child: TextField(
                                      controller: _textController,
                                      expands: true,
                                      maxLines: null,
                                      minLines: null,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFFE0E0E0),
                                        height: 1.6,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Type something...',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF757575),
                                        ),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                      ),
                                      onChanged: (_) => _saveCurrentText(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          color: const Color(0xFF3D3D3D),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: const Color(0xFF252526),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Saved',
                                      style: TextStyle(
                                        color: Color(0xFFFFB6C1),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3D3D3D),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_notes.length}',
                                        style: const TextStyle(
                                          color: Color(0xFFFFB6C1),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _notes.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No notes yet',
                                            style: TextStyle(
                                              color: Color(0xFF757575),
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: _notes.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final note = _notes[index];
                                            return _NoteCard(
                                              note: note,
                                              onTap: () => _loadNote(note),
                                              onDelete: () =>
                                                  _deleteNote(index),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
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

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFF757575),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(
          colors: WindowButtonColors(
            iconNormal: const Color(0xFFFFB6C1),
            mouseOver: const Color(0xFF3D3D3D),
            mouseDown: const Color(0xFF555555),
            iconMouseOver: const Color(0xFFFFB6C1),
            iconMouseDown: const Color(0xFFFFB6C1),
          ),
        ),
        MaximizeWindowButton(
          colors: WindowButtonColors(
            iconNormal: const Color(0xFFFFB6C1),
            mouseOver: const Color(0xFF3D3D3D),
            mouseDown: const Color(0xFF555555),
            iconMouseOver: const Color(0xFFFFB6C1),
            iconMouseDown: const Color(0xFFFFB6C1),
          ),
        ),
        CloseWindowButton(
          colors: WindowButtonColors(
            iconNormal: const Color(0xFFFFB6C1),
            mouseOver: const Color(0xFFE74C3C),
            mouseDown: const Color(0xFFC0392B),
            iconMouseOver: Colors.white,
            iconMouseDown: Colors.white,
          ),
        ),
      ],
    );
  }
}
