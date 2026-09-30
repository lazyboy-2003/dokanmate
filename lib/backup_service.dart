import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:sqflite/sqflite.dart';

class DokanMateBackupService {
  DokanMateBackupService._();

  static const _storage = FlutterSecureStorage();
  static const _backupFileName = 'dokanmate_backup.json';
  static const _scopes = <String>[drive.DriveApi.driveAppdataScope];
  static const _tables = <String>[
    'business',
    'parties',
    'products',
    'sales',
    'sale_items',
    'purchases',
    'purchase_items',
    'payments',
    'expenses',
    'stock_moves',
    'audit',
  ];

  static Future<void>? _initialized;

  static Future<void> _initGoogle() {
    return _initialized ??= GoogleSignIn.instance.initialize();
  }

  static Future<GoogleSignInAccount> _signIn() async {
    await _initGoogle();
    var user = GoogleSignIn.instance.currentUser;
    if (user == null) {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw StateError('Google Sign-In is not supported on this Android build.');
      }
      user = await GoogleSignIn.instance.authenticate();
    }
    return user;
  }

  static Future<drive.DriveApi> _drive({bool interactive = true}) async {
    final user = interactive
        ? await _signIn()
        : await _silentUser();
    if (user == null) {
      throw StateError('No Google account is connected to DokanMate.');
    }

    GoogleSignInClientAuthorization authorization;
    try {
      authorization = await user.authorizationClient.authorizationForScopes(_scopes) ??
          await user.authorizationClient.authorizeScopes(_scopes);
    } catch (_) {
      authorization = await user.authorizationClient.authorizeScopes(_scopes);
    }

    final authClient = authorization.authClient(scopes: _scopes);
    return drive.DriveApi(authClient);
  }

  static Future<GoogleSignInAccount?> _silentUser() async {
    await _initGoogle();
    return GoogleSignIn.instance.currentUser;
  }

  static Future<Map<String, dynamic>> _snapshot(Database db) async {
    final data = <String, dynamic>{
      'format': 'dokanmate-backup',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'tables': <String, dynamic>{},
    };

    final tables = data['tables'] as Map<String, dynamic>;
    for (final table in _tables) {
      final rows = await db.query(table);
      tables[table] = rows
          .map((row) => row.map((key, value) => MapEntry(key, value)))
          .toList();
    }
    return data;
  }

  static Future<List<int>> _backupBytes(Database db) async {
    final snapshot = await _snapshot(db);
    return utf8.encode(jsonEncode(snapshot));
  }

  static Future<drive.File?> _findBackup(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName' and trashed = false",
      pageSize: 10,
      $fields: 'files(id,name,size,modifiedTime)',
    );
    final files = result.files ?? const <drive.File>[];
    return files.isEmpty ? null : files.first;
  }

  static Future<String> backup(Database db) async {
    final api = await _drive();
    final bytes = await _backupBytes(db);
    final media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    final existing = await _findBackup(api);
    if (existing?.id != null) {
      await api.files.update(
        drive.File(name: _backupFileName, mimeType: 'application/json'),
        existing!.id!,
        uploadMedia: media,
        $fields: 'id,name,modifiedTime,size',
      );
    } else {
      await api.files.create(
        drive.File(
          name: _backupFileName,
          mimeType: 'application/json',
          parents: const ['appDataFolder'],
        ),
        uploadMedia: media,
        $fields: 'id,name,modifiedTime,size',
      );
    }

    final now = DateTime.now().toIso8601String();
    await _storage.write(key: 'dokanmate_backup_email', value: (await _signIn()).email);
    await _storage.write(key: 'dokanmate_last_backup', value: now);
    return now;
  }

  static Future<Map<String, dynamic>> _downloadBackup(drive.DriveApi api) async {
    final file = await _findBackup(api);
    if (file?.id == null) {
      throw StateError('No DokanMate backup was found in this Google account.');
    }

    final result = await api.files.get(
      file!.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    if (result is! drive.Media) {
      throw StateError('Google Drive did not return the backup file.');
    }

    final bytes = <int>[];
    await for (final chunk in result.stream) {
      bytes.addAll(chunk);
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw StateError('Backup file is invalid.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<void> restore(Database db) async {
    final api = await _drive();
    final backup = await _downloadBackup(api);
    if (backup['format'] != 'dokanmate-backup') {
      throw StateError('This file is not a valid DokanMate backup.');
    }

    final rawTables = backup['tables'];
    if (rawTables is! Map) {
      throw StateError('Backup tables are missing.');
    }

    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _tables) {
      final rawRows = rawTables[table];
      if (rawRows is List) {
        tables[table] = rawRows
            .whereType<Map>()
            .map((row) => Map<String, Object?>.from(row))
            .toList();
      } else {
        tables[table] = <Map<String, Object?>>[];
      }
    }

    await db.transaction((tx) async {
      // Delete children first so foreign-key-enabled databases remain safe.
      for (final table in const [
        'audit',
        'stock_moves',
        'payments',
        'expenses',
        'sale_items',
        'purchase_items',
        'sales',
        'purchases',
        'parties',
        'products',
        'business',
      ]) {
        await tx.delete(table);
      }

      for (final table in _tables) {
        for (final row in tables[table]!) {
          await tx.insert(table, row);
        }
      }
    });

    await _storage.write(
      key: 'dokanmate_last_restore',
      value: DateTime.now().toIso8601String(),
    );
  }

  static Future<String?> connectedEmail() => _storage.read(key: 'dokanmate_backup_email');

  static Future<String?> lastBackup() => _storage.read(key: 'dokanmate_last_backup');

  static Future<bool> autoBackupEnabled() async =>
      (await _storage.read(key: 'dokanmate_auto_backup')) == '1';

  static Future<void> setAutoBackup(bool enabled) async {
    await _storage.write(key: 'dokanmate_auto_backup', value: enabled ? '1' : '0');
  }

  static Future<void> disconnect() async {
    await _initGoogle();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _storage.delete(key: 'dokanmate_backup_email');
    await _storage.delete(key: 'dokanmate_last_backup');
    await _storage.write(key: 'dokanmate_auto_backup', value: '0');
  }

  static Future<void> maybeAutoBackup(Database db) async {
    if (!await autoBackupEnabled()) return;
    final user = await _silentUser();
    if (user == null) return;

    final last = await lastBackup();
    if (last != null) {
      final when = DateTime.tryParse(last);
      if (when != null && DateTime.now().difference(when).inHours < 24) return;
    }

    try {
      await backup(db);
    } catch (_) {
      // Automatic backup must never block or crash the app.
    }
  }
}

class BackupRestorePage extends StatefulWidget {
  final Database db;
  const BackupRestorePage(this.db, {super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool busy = false;
  bool autoBackup = false;
  String? email;
  String? lastBackup;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      DokanMateBackupService.connectedEmail(),
      DokanMateBackupService.lastBackup(),
      DokanMateBackupService.autoBackupEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      email = values[0] as String?;
      lastBackup = values[1] as String?;
      autoBackup = values[2] as bool;
    });
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup error: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _date(String? value) {
    if (value == null) return 'Never';
    final d = DateTime.tryParse(value)?.toLocal();
    if (d == null) return value;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _restore() async {
    if (email == null) {
      await _run(
        () async => DokanMateBackupService.restore(widget.db),
        'Data restored successfully.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore business data?'),
        content: const Text(
          'This will replace the current DokanMate data with the latest Google Drive backup. '
          'Make sure you have a current backup before continuing.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(
      () async => DokanMateBackupService.restore(widget.db),
      'Data restored successfully. Please reopen the affected pages.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = email != null && email!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFEEF0FF),
                      child: Icon(Icons.cloud_done_rounded, color: connected ? const Color(0xFF16A34A) : const Color(0xFF5B5CE2)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            connected ? 'Google Drive Connected' : 'Google Drive Not Connected',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            connected ? email! : 'Use the merchant\'s own Google account',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF777B86)),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text('Last backup: ${_date(lastBackup)}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 14),
                  if (!connected)
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => _run(
                                () async {
                                  // A real Drive authorization is requested by backup().
                                  await DokanMateBackupService.backup(widget.db);
                                },
                                'Google Drive connected and backup completed.',
                              ),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Connect Google Drive'),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => _run(
                                () => DokanMateBackupService.backup(widget.db),
                                'Backup completed successfully.',
                              ),
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: const Text('Backup Now'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _restore,
                      icon: const Icon(Icons.cloud_download_rounded),
                      label: const Text('Restore Backup'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Automatic Backup'),
                      subtitle: const Text('When enabled, DokanMate checks once a day when the app is opened.'),
                      value: autoBackup,
                      onChanged: busy
                          ? null
                          : (value) async {
                              await DokanMateBackupService.setAutoBackup(value);
                              if (mounted) setState(() => autoBackup = value);
                            },
                    ),
                    TextButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              await DokanMateBackupService.disconnect();
                              await _load();
                            },
                      icon: const Icon(Icons.link_off_rounded),
                      label: const Text('Disconnect Google Drive'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Backup is stored in DokanMate\'s private Google Drive application-data area. '
                'It is not a normal shared Drive folder. Your Google password is never stored by DokanMate.',
                style: TextStyle(fontSize: 12, height: 1.45),
              ),
            ),
          ),
          if (busy) const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
