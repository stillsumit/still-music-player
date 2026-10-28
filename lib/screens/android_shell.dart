import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../models/song.dart';
import '../widgets/glass_box.dart';

class AndroidShell extends StatelessWidget {
  final Player player;
  final bool isPlaying;
  final Song? currentSong;
  final List<Song> playlist;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final VoidCallback onPickFolder;
  final Function(int) onSelectSong;
  final VoidCallback onNext;

  const AndroidShell({
    super.key,
    required this.player,
    required this.isPlaying,
    required this.currentSong,
    required this.playlist,
    required this.currentIndex,
    required this.position,
    required this.duration,
    required this.onPickFolder,
    required this.onSelectSong,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Library (${playlist.length})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: onPickFolder,
          ),
        ],
      ),
      body: Stack(
        children: [
          playlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_music_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      const Text("Tap the folder icon above to add music."),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120, top: 8),
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    final song = playlist[index];
                    final isSelected = index == currentIndex;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Colors.purpleAccent.withValues(alpha: 0.2)
                            : Colors.white10,
                        child: Icon(
                          isSelected ? Icons.graphic_eq : Icons.music_note,
                          color: isSelected
                              ? Colors.purpleAccent
                              : Colors.white70,
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.purpleAccent
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: const TextStyle(color: Colors.white38),
                      ),
                      onTap: () => onSelectSong(index),
                    );
                  },
                ),

          // Floating Glass Mini-Player Dock
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: GlassBox(
              height: 72,
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: currentSong?.artwork != null
                        ? Image.memory(
                            currentSong!.artwork!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            color: Colors.white.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentSong?.title ?? "No track playing",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          currentSong?.artist ?? "Tap a song to play",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 34,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => player.playOrPause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: onNext,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
