import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color primary = Color(0xFFFFB6C1);
  static const Color background = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF2B2B2B);
  static const Color surfaceLight = Color(0xFF252526);
  static const Color border = Color(0xFF3D3D3D);
  static const Color text = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF757575);
  static const Color closeButton = Color(0xFFE74C3C);
  static const Color closeButtonPressed = Color(0xFFC0392B);
}

class AppSizes {
  static const double windowBorder = 1;
  static const double small = 4;
  static const double medium = 8;
  static const double large = 12;
  static const double xlarge = 16;
  static const double xxlarge = 24;
  static const double logo = 28;
  static const double borderRadius = 8;
  static const double cardBorderRadius = 10;
}

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
      title: 'Virazx Quick Notes',
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
      final savedText = prefs.getString('current_text');

      List<Note> loadedNotes = [];
      if (savedNotesJson?.isNotEmpty == true) {
        loadedNotes = (jsonDecode(savedNotesJson!) as List)
            .map((json) => Note.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      if (savedText != null) _textController.text = savedText;

      if (mounted) {
        setState(() {
          _notes = loadedNotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Load error: $e');
        setState(() => _isLoading = false);
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
        backgroundColor: AppColors.surface,
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
        backgroundColor: AppColors.surface,
        title: const Text(
          'Name your note',
          style: TextStyle(color: AppColors.text),
        ),
        content: TextField(
          controller: _titleController,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(
            hintText: 'Enter name...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              if (title.isNotEmpty) {
                setState(() =>
                    _notes.add(Note(title: title, text: _textController.text)));
                await _saveNotes();
                if (mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Note saved!');
                }
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primary),
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
        color: AppColors.primary,
        width: AppSizes.windowBorder,
        child: Column(
          children: [
            WindowTitleBarBox(
              child: Container(
                color: AppColors.background,
                child: Row(
                  children: [
                    Expanded(
                      child: MoveWindow(
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppSizes.xlarge),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: AppSizes.logo,
                                  height: AppSizes.logo,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Virazx Quick Note',
                                  style: TextStyle(
                                    color: AppColors.primary,
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
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            color: AppColors.surface,
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(AppSizes.large),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius: BorderRadius.circular(
                                            AppSizes.borderRadius),
                                      ),
                                      child: IconButton(
                                        onPressed: _showSaveDialog,
                                        icon: const Icon(Icons.arrow_downward,
                                            size: 20),
                                        color: AppColors.primary,
                                        tooltip: 'Save note',
                                        splashRadius: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSizes.xxlarge,
                                        vertical: AppSizes.medium),
                                    child: TextField(
                                      controller: _textController,
                                      expands: true,
                                      maxLines: null,
                                      minLines: null,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.text,
                                        height: 1.6,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Start typing your notes...',
                                        hintStyle: TextStyle(
                                            color: AppColors.textMuted),
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
                            width: AppSizes.windowBorder,
                            color: AppColors.border),
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: AppColors.surfaceLight,
                            padding: const EdgeInsets.all(AppSizes.xlarge),
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
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSizes.medium,
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_notes.length}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.large),
                                Expanded(
                                  child: _notes.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No notes yet',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: _notes.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(
                                                  height: AppSizes.medium),
                                          itemBuilder: (context, index) =>
                                              _NoteCard(
                                            note: _notes[index],
                                            onTap: () =>
                                                _loadNote(_notes[index]),
                                            onDelete: () => _deleteNote(index),
                                          ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
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
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.large, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.small),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.textMuted,
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
    final defaultColors = WindowButtonColors(
      iconNormal: AppColors.primary,
      mouseOver: AppColors.border,
      mouseDown: const Color(0xFF555555),
      iconMouseOver: AppColors.primary,
      iconMouseDown: AppColors.primary,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: defaultColors),
        MaximizeWindowButton(colors: defaultColors),
        CloseWindowButton(
          colors: WindowButtonColors(
            iconNormal: AppColors.primary,
            mouseOver: AppColors.closeButton,
            mouseDown: AppColors.closeButtonPressed,
            iconMouseOver: Colors.white,
            iconMouseDown: Colors.white,
          ),
        ),
      ],
    );
  }
}
