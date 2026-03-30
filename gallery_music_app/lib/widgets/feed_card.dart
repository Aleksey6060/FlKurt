import 'dart:io';
import 'package:flutter/material.dart';
import '../models/media_item.dart';

class FeedCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;

  const FeedCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: item.isVideo
                  ? Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.2),
                      child: Center(
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          size: 40,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                    )
                  : Image.file(File(item.path), fit: BoxFit.cover),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Text(
                  '${item.date.day}.${item.date.month.toString().padLeft(2, '0')}.${item.date.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
