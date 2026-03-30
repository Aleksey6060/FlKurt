import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/music_item.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _musicBox = Hive.box<MusicItem>('music');
  final _player = AudioPlayer();

  int? _currentIndex;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((pos) {
      setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playTrack(int index) async {
    final items = _musicBox.values.toList();
    final item = items[index];
    await _player.play(UrlSource(item.url));
    setState(() {
      _currentIndex = index;
      _isPlaying = true;
    });
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить аудио'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL аудио'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                _musicBox.add(
                  MusicItem(
                    title: titleController.text,
                    url: urlController.text,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Медиатека',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _musicBox.listenable(),
            builder: (context, Box<MusicItem> box, _) {
              if (box.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_music_rounded,
                              size: 80, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(height: 20),
                          const Text('У вас пока нет музыки',
                              style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final items = box.values.toList();
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      final isActive = _currentIndex == index;
                      return _buildMusicCard(item, index, isActive, box);
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 240)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Добавить трек'),
        ),
      ),
      bottomSheet: _currentIndex != null ? _buildPlayerSheet() : null,
    );
  }

  Widget _buildMusicCard(MusicItem item, int index, bool isActive, Box<MusicItem> box) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
            : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isActive && _isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
            color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showOptions(index, box),
        ),
        onTap: () {
          if (isActive && _isPlaying) {
            _player.pause();
            setState(() => _isPlaying = false);
          } else if (isActive) {
            _player.resume();
            setState(() => _isPlaying = true);
          } else {
            _playTrack(index);
          }
        },
      ),
    );
  }

  void _showOptions(int index, Box<MusicItem> box) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Удалить из библиотеки'),
              onTap: () {
                if (_currentIndex == index) {
                  _player.stop();
                  setState(() {
                    _currentIndex = null;
                    _isPlaying = false;
                  });
                }
                box.deleteAt(index);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSheet() {
    final items = _musicBox.values.toList();
    if (_currentIndex == null || _currentIndex! >= items.length) {
      return const SizedBox.shrink();
    }
    final current = items[_currentIndex!];
    
    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.music_note_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                iconSize: 44,
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  if (_isPlaying) {
                    _player.pause();
                    setState(() => _isPlaying = false);
                  } else {
                    _player.resume();
                    setState(() => _isPlaying = true);
                  }
                },
              ),
            ],
          ),
          const Spacer(),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
              onChanged: (value) => _player.seek(Duration(seconds: value.toInt())),
            ),
          ),
        ],
      ),
    );
  }
}
