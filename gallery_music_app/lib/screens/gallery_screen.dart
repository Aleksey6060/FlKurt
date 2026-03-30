import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import '../models/media_item.dart';
import '../widgets/feed_card.dart';
import 'media_viewer.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _mediaBox = Hive.box<MediaItem>('media');
  final _picker = ImagePicker();

  Future<LocationData?> _getLocation() async {
    final location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) return null;
    }

    return await location.getLocation();
  }

  Future<void> _addMedia(bool isVideo) async {
    final XFile? file;
    if (isVideo) {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await _picker.pickImage(source: ImageSource.gallery);
    }

    if (file == null) return;

    double? lat;
    double? lon;

    if (!isVideo) {
      final locData = await _getLocation();
      if (locData != null) {
        lat = locData.latitude;
        lon = locData.longitude;
      }
    }

    final item = MediaItem(
      path: file.path,
      isVideo: isVideo,
      date: DateTime.now(),
      latitude: lat,
      longitude: lon,
    );

    await _mediaBox.add(item);
    setState(() {});
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
                'Коллекция',
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
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _mediaBox.listenable(),
            builder: (context, Box<MediaItem> box, _) {
              if (box.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_mosaic_rounded,
                              size: 80, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 20),
                          const Text('Ваша галерея пуста',
                              style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final items = box.values.toList().reversed.toList();
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return FeedCard(
                        item: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MediaViewer(item: item),
                            ),
                          );
                        },
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFab(
              onPressed: () => _addMedia(false),
              icon: Icons.add_photo_alternate_rounded,
              color: Theme.of(context).colorScheme.primary,
              label: 'Фото',
            ),
            const SizedBox(height: 12),
            _buildFab(
              onPressed: () => _addMedia(true),
              icon: Icons.video_library_rounded,
              color: Theme.of(context).colorScheme.secondary,
              label: 'Видео',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return FloatingActionButton.extended(
      heroTag: label,
      onPressed: onPressed,
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
