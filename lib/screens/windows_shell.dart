import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../models/song.dart';
import '../widgets/glass_box.dart';

class WindowsShell extends StatelessWidget {
  final Player player;
  final bool isPlaying;
  final Song? currentSong;
  final List<Song> playlist;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final VoidCallback onPickFolder;
  final VoidCallback onOpenDrive;
  final Function(int) onSelectSong;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const WindowsShell({
    super.key,
    required this.player,
    required this.isPlaying,
    required this.currentSong,
    required this.playlist,
    required this.currentIndex,
    required this.position,
    required this.duration,
    required this.onPickFolder,
    required this.onOpenDrive,
    required this.onSelectSong,
    required this.onNext,
    required this.onPrevious,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Sidebar
          GlassBox(
            width: 250,
            borderRadius: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.blur_on, color: Colors.purpleAccent, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Aura Music",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                _sidebarItem(
                  Icons.library_music,
                  "Library (${playlist.length})",
                  active: true,
                  onTap: () {},
                ),
                _sidebarItem(
                  Icons.cloud_outlined,
                  "Google Drive",
                  onTap: onOpenDrive,
                ),
                _sidebarItem(Icons.favorite_border, "Favorites", onTap: () {}),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onPickFolder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text("Scan Local Folder"),
                ),
              ],
            ),
          ),

          // Main View
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Text(
                        "Tracks",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Song List View
                Expanded(
                  child: playlist.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "No songs loaded. Open a local folder or connect Google Drive.",
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: playlist.length,
                          itemBuilder: (context, index) {
                            final song = playlist[index];
                            final isSelected = index == currentIndex;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isSelected
                                    ? Icons.graphic_eq
                                    : (song.isFromDrive
                                          ? Icons.cloud
                                          : Icons.music_note),
                                color: isSelected
                                    ? Colors.purpleAccent
                                    : (song.isFromDrive
                                          ? Colors.lightBlueAccent
                                          : Colors.white54),
                              ),
                              title: Text(
                                song.title,
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
                                song.isFromDrive
                                    ? "Google Drive Stream"
                                    : song.artist,
                                style: TextStyle(
                                  color: song.isFromDrive
                                      ? Colors.lightBlueAccent.withValues(
                                          alpha: 0.7,
                                        )
                                      : Colors.white38,
                                ),
                              ),
                              trailing: isSelected && isPlaying
                                  ? const Text(
                                      "Playing",
                                      style: TextStyle(
                                        color: Colors.purpleAccent,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              onTap: () => onSelectSong(index),
                            );
                          },
                        ),
                ),

                // Bottom Glass Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GlassBox(
                    height: 108,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scrubber Slider + Timers
                        Row(
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  trackHeight: 3,
                                  activeTrackColor: Colors.purpleAccent,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: duration.inMilliseconds > 0
                                      ? position.inMilliseconds
                                            .clamp(0, duration.inMilliseconds)
                                            .toDouble()
                                      : 0.0,
                                  max: duration.inMilliseconds > 0
                                      ? duration.inMilliseconds.toDouble()
                                      : 1.0,
                                  onChanged: (val) {
                                    player.seek(
                                      Duration(milliseconds: val.toInt()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),

                        // Track Info & Controls
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      child: Icon(
                                        currentSong?.isFromDrive == true
                                            ? Icons.cloud_done
                                            : Icons.album,
                                        color: currentSong?.isFromDrive == true
                                            ? Colors.lightBlueAccent
                                            : Colors.white54,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    currentSong?.title ?? "No track selected",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentSong?.isFromDrive == true
                                        ? "Google Drive"
                                        : (currentSong?.artist ??
                                              "Local Track"),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: currentSong?.isFromDrive == true
                                          ? Colors.lightBlueAccent.withValues(
                                              alpha: 0.8,
                                            )
                                          : Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                size: 26,
                              ),
                              onPressed: onPrevious,
                            ),
                            IconButton(
                              iconSize: 38,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => player.playOrPause(),
                            ),
                            IconButton(
                              iconSize: 26,
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: onNext,
                            ),
                          ],
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
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String title, {
    bool active = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: active ? Colors.purpleAccent : Colors.white70,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: active
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        onTap: onTap,
      ),
    );
  }
}
