import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    ),
    home: const NotesPage(),
  ));
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _notes = [];
  int? _editingIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (_editingIndex == null) {
        _notes.add(text);
      } else {
        _notes[_editingIndex!] = text;
      }
      _controller.clear();
      _editingIndex = null;
    });
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
      if (_editingIndex == index) {
        _controller.clear();
        _editingIndex = null;
      }
    });
  }

  void _startEdit(int index) {
    setState(() {
      _controller.text = _notes[index];
      _editingIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _editingIndex != null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF4C1D95),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Заметки'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        labelText: isEditing
                            ? 'Редактирование заметки'
                            : 'Новая заметка',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      onSubmitted: (_) => _saveNote(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveNote,
                            child: Text(isEditing ? 'Обновить' : 'Сохранить'),
                          ),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _controller.clear();
                                _editingIndex = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.12),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Отмена'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1E293B),
                              Color(0xFF4C1D95),
                            ],
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            _notes[index],
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () => _startEdit(index),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.redAccent.shade200,
                            onPressed: () => _deleteNote(index),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}