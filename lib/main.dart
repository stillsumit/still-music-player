import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import 'models/song.dart';
import 'services/drive_service.dart';
import 'screens/windows_shell.dart';
import 'screens/android_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const GlassPlayerApp());
}

class GlassPlayerApp extends StatelessWidget {
  const GlassPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aura Player',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
      ),
      home: const MainAdaptiveScreen(),
    );
  }
}

class MainAdaptiveScreen extends StatefulWidget {
  const MainAdaptiveScreen({super.key});

  @override
  State<MainAdaptiveScreen> createState() => _MainAdaptiveScreenState();
}

class _MainAdaptiveScreenState extends State<MainAdaptiveScreen> {
  late final Player player;
  final DriveService driveService = DriveService();

  List<Song> playlist = [];
  int currentIndex = -1;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    player = Player();

    player.stream.playing.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });

    player.stream.position.listen((pos) {
      if (mounted) setState(() => position = pos);
    });

    player.stream.duration.listen((dur) {
      if (mounted) setState(() => duration = dur);
    });

    player.stream.completed.listen((completed) {
      if (completed) playNext();
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> scanFolder() async {
    final String? folderPath = await FilePicker.getDirectoryPath();
    if (folderPath == null) return;

    final dir = Directory(folderPath);
    final List<Song> foundSongs = [];
    final audioExtensions = [
      '.mp3',
      '.flac',
      '.wav',
      '.aac',
      '.m4a',
      '.ogg',
      '.opus',
    ];

    try {
      final files = dir.listSync(recursive: true, followLinks: false);
      for (final entity in files) {
        if (entity is File) {
          final isAudio = audioExtensions.any(
            (ext) => entity.path.toLowerCase().endsWith(ext),
          );
          if (isAudio) {
            foundSongs.add(Song.fromPath(entity.path));
          }
        }
      }

      setState(() {
        playlist = foundSongs;
      });

      if (playlist.isNotEmpty && currentIndex == -1) {
        playSong(0);
      }
    } catch (e) {
      debugPrint("Error reading folder: $e");
    }
  }

  // Handle Google Drive Connection & Folder Dialog
  Future<void> openDriveDialog() async {
    if (!driveService.isAuthenticated) {
      final success = await driveService.authenticate();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to authenticate with Google Drive."),
            ),
          );
        }
        return;
      }
    }

    // Fetch folders
    final folders = await driveService.getMusicFolders();
    if (!mounted) return;

    // Show a dialog to select the folder
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: const Text("Select Drive Music Folder"),
          content: SizedBox(
            width: 400,
            height: 300,
            child: folders.isEmpty
                ? const Center(
                    child: Text("No folders found in your Google Drive."),
                  )
                : ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, idx) {
                      final folder = folders[idx];
                      return ListTile(
                        leading: const Icon(
                          Icons.folder,
                          color: Colors.lightBlueAccent,
                        ),
                        title: Text(folder.name),
                        onTap: () async {
                          Navigator.pop(context);
                          final songs = await driveService
                              .getAudioFilesFromFolder(folder.id);
                          if (songs.isNotEmpty) {
                            setState(() {
                              playlist = songs;
                              currentIndex = -1;
                            });
                            playSong(0);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "No audio files found in that folder.",
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= playlist.length) return;

    setState(() {
      currentIndex = index;
    });

    final song = playlist[index];

    // Case 1: Stream from Google Drive
    if (song.isFromDrive && song.driveFileId != null) {
      final streamUrl =
          'https://www.googleapis.com/drive/v3/files/${song.driveFileId}?alt=media';
      final token = driveService.accessToken;

      await player.open(
        Media(streamUrl, httpHeaders: {'Authorization': 'Bearer $token'}),
      );
      return;
    }

    // Case 2: Play from Local Disk
    final currentFile = File(song.path);
    await player.open(Media(currentFile.path));

    try {
      final metadata = readMetadata(currentFile, getImage: true);
      final rawArtwork = metadata.pictures.isNotEmpty
          ? metadata.pictures.first.bytes
          : null;
      final parsedTitle = metadata.title?.trim().isNotEmpty == true
          ? metadata.title!
          : song.title;
      final parsedArtist = metadata.artist?.trim().isNotEmpty == true
          ? metadata.artist!
          : "Unknown Artist";

      if (mounted) {
        setState(() {
          playlist[index] = song.copyWith(
            title: parsedTitle,
            artist: parsedArtist,
            artwork: rawArtwork,
          );
        });
      }
    } catch (e) {
      debugPrint("Could not parse metadata: $e");
    }
  }

  void playNext() {
    if (playlist.isEmpty) return;
    final nextIndex = (currentIndex + 1) % playlist.length;
    playSong(nextIndex);
  }

  void playPrevious() {
    if (playlist.isEmpty) return;
    final prevIndex = (currentIndex - 1 < 0)
        ? playlist.length - 1
        : currentIndex - 1;
    playSong(prevIndex);
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = (currentIndex >= 0 && currentIndex < playlist.length)
        ? playlist[currentIndex]
        : null;

    return Stack(
      children: [
        Container(color: const Color(0xFF0C0C0E)),
        Positioned(
          top: -90,
          left: -90,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepPurple.withValues(alpha: 0.35),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          right: -60,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.pinkAccent.withValues(alpha: 0.18),
            ),
          ),
        ),
        Platform.isWindows
            ? WindowsShell(
                player: player,
                isPlaying: isPlaying,
                currentSong: currentSong,
                playlist: playlist,
                currentIndex: currentIndex,
                position: position,
                duration: duration,
                onPickFolder: scanFolder,
                onOpenDrive: openDriveDialog,
                onSelectSong: playSong,
                onNext: playNext,
                onPrevious: playPrevious,
              )
            : AndroidShell(
                player: player,
                isPlaying: isPlaying,
                currentSong: currentSong,
                playlist: playlist,
                currentIndex: currentIndex,
                position: position,
                duration: duration,
                onPickFolder: scanFolder,
                onSelectSong: playSong,
                onNext: playNext,
              ),
      ],
    );
  }
}
