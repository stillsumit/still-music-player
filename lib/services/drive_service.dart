import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/secrets.dart';
import '../models/song.dart';

class DriveFolder {
  final String id;
  final String name;

  DriveFolder({required this.id, required this.name});
}

class DriveService {
  static const String _clientId = AppSecrets.googleClientId;
  static const String _clientSecret = AppSecrets.googleClientSecret;
  static const String _storageKey = "aura_google_drive_creds";

  AutoRefreshingAuthClient? _authClient;
  drive.DriveApi? _driveApi;

  bool get isAuthenticated => _authClient != null;
  String? get accessToken => _authClient?.credentials.accessToken.data;

  // 1. Silent login on startup (Uses _storageKey)
  Future<bool> trySilentLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null) return false;

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final credentials = AccessCredentials.fromJson(jsonMap);

      final id = ClientId(
        _clientId,
        _clientSecret.isEmpty ? null : _clientSecret,
      );
      _authClient = autoRefreshingClient(id, credentials, http.Client());

      // Auto-save refreshed tokens to disk
      _authClient!.credentialUpdates.listen((updatedCreds) {
        _saveCredentials(updatedCreds);
      });

      _driveApi = drive.DriveApi(_authClient!);
      return true;
    } catch (e) {
      debugPrint("Silent login error: $e");
      await signOut();
      return false;
    }
  }

  // 2. Interactive consent login (First time only)
  Future<bool> authenticate() async {
    try {
      final id = ClientId(
        _clientId,
        _clientSecret.isEmpty ? null : _clientSecret,
      );
      final scopes = [drive.DriveApi.driveReadonlyScope];

      _authClient = await clientViaUserConsent(id, scopes, (url) async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      });

      // Save token to disk
      await _saveCredentials(_authClient!.credentials);

      _authClient!.credentialUpdates.listen((updatedCreds) {
        _saveCredentials(updatedCreds);
      });

      _driveApi = drive.DriveApi(_authClient!);
      return true;
    } catch (e) {
      debugPrint("OAuth Authentication Error: $e");
      return false;
    }
  }

  // 3. Persist credentials (Uses _storageKey)
  Future<void> _saveCredentials(AccessCredentials creds) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(creds.toJson());
    await prefs.setString(_storageKey, jsonString);
  }

  // 4. Disconnect and wipe token (Uses _storageKey)
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _authClient?.close();
    _authClient = null;
    _driveApi = null;
  }

  // 5. Fetch Folders (Only owned by you)
  Future<List<DriveFolder>> getMusicFolders() async {
    if (_driveApi == null) return [];

    try {
      final fileList = await _driveApi!.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and trashed = false and 'me' in owners",
        $fields: "files(id, name)",
        pageSize: 50,
      );

      return (fileList.files ?? [])
          .map((f) => DriveFolder(id: f.id ?? '', name: f.name ?? 'Untitled'))
          .toList();
    } catch (e) {
      debugPrint("Error fetching Drive folders: $e");
      return [];
    }
  }

  // 6. Fetch Audio files only
  Future<List<Song>> getAudioFilesFromFolder(String folderId) async {
    if (_driveApi == null) return [];

    const allowedAudioExtensions = [
      '.mp3',
      '.flac',
      '.wav',
      '.aac',
      '.m4a',
      '.ogg',
      '.opus',
      '.alac',
      '.aiff',
      '.wma',
    ];

    try {
      final fileList = await _driveApi!.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: "files(id, name, mimeType)",
        pageSize: 150,
      );

      final files = fileList.files ?? [];

      return files
          .where((f) {
            if (f.id == null || f.name == null) return false;

            final fileName = f.name!.toLowerCase();
            final mime = f.mimeType?.toLowerCase() ?? '';

            if (mime.startsWith('image/') || mime.startsWith('video/')) {
              return false;
            }

            final hasAudioExtension = allowedAudioExtensions.any(
              (ext) => fileName.endsWith(ext),
            );
            final hasAudioMime = mime.startsWith('audio/');

            return hasAudioExtension || hasAudioMime;
          })
          .map((f) => Song.fromDriveFile(f.id!, f.name!))
          .toList();
    } catch (e) {
      debugPrint("Error fetching files from folder: $e");
      return [];
    }
  }
}
