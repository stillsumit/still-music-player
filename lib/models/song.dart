import 'dart:typed_data';

class Song {
  final String title;
  final String artist;
  final String path;
  final String? driveFileId;
  final Duration? duration;
  final Uint8List? artwork;
  final bool isFromDrive;

  Song({
    required this.title,
    this.artist = 'Local File',
    required this.path,
    this.driveFileId,
    this.duration,
    this.artwork,
    this.isFromDrive = false,
  });

  factory Song.fromPath(String fullPath) {
    final fileName = fullPath.split(RegExp(r'[/\\]')).last;
    final cleanTitle = fileName.replaceAll(
      RegExp(r'\.(mp3|flac|wav|aac|m4a|ogg|opus)$', caseSensitive: false),
      '',
    );
    return Song(title: cleanTitle, path: fullPath);
  }

  factory Song.fromDriveFile(String id, String fileName) {
    final cleanTitle = fileName.replaceAll(
      RegExp(r'\.(mp3|flac|wav|aac|m4a|ogg|opus)$', caseSensitive: false),
      '',
    );
    return Song(
      title: cleanTitle,
      artist: 'Google Drive',
      path: id,
      driveFileId: id,
      isFromDrive: true,
    );
  }

  Song copyWith({
    String? title,
    String? artist,
    Uint8List? artwork,
    Duration? duration,
  }) {
    return Song(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      path: path,
      driveFileId: driveFileId,
      duration: duration ?? this.duration,
      artwork: artwork ?? this.artwork,
      isFromDrive: isFromDrive,
    );
  }
}
