import 'dart:async';
import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../../core/config/google_config.dart';

/// Um arquivo de backup no Drive.
class DriveBackup {
  const DriveBackup({
    required this.id,
    required this.name,
    required this.createdAt,
    this.sizeBytes,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int? sizeBytes;
}

/// O login falhou, foi cancelado ou a permissão do Drive foi negada.
class DriveAuthException implements Exception {
  const DriveAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Backup do Notizbuch numa pasta visível "Mein Notizbuch" do Google Drive.
///
/// Usa o escopo `drive.file`: o app só enxerga as pastas e arquivos que ele
/// mesmo criou, e nada mais do seu Drive.
class DriveBackupService {
  DriveBackupService._();
  static final DriveBackupService instance = DriveBackupService._();

  static const String folderName = 'Mein Notizbuch';
  static const List<String> scopes = [drive.DriveApi.driveFileScope];
  static const String _folderMime = 'application/vnd.google-apps.folder';

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  Future<void>? _init;
  GoogleSignInAccount? _account;

  /// Conta conectada nesta execução do app, se houver.
  GoogleSignInAccount? get account => _account;

  Future<void> _ensureInitialized() {
    return _init ??= _signIn.initialize(serverClientId: googleServerClientId);
  }

  /// Login com escolha de conta e pedido de permissão do Drive.
  /// Retorna o e-mail da conta.
  Future<String> connect() async {
    if (!isDriveBackupSupported) {
      throw const DriveAuthException(
        'O backup no Google Drive ainda não está disponível no iPhone.',
      );
    }
    if (!isGoogleConfigured) {
      throw const DriveAuthException(
        'O login Google ainda não foi configurado no app '
        '(google_config.dart).',
      );
    }
    await _ensureInitialized();
    try {
      final account = await _signIn.authenticate(scopeHint: scopes);
      _account = account;
      await _api(interactive: true); // já pede a permissão do Drive
      return account.email;
    } on GoogleSignInException catch (e) {
      throw DriveAuthException(_describe(e));
    }
  }

  /// Reconecta sem mostrar nada (usado no backup automático).
  /// Retorna `false` se for preciso entrar de novo pela tela de backup.
  Future<bool> reconnectSilently() async {
    if (!isDriveBackupSupported || !isGoogleConfigured) return false;
    await _ensureInitialized();
    try {
      final result = _signIn.attemptLightweightAuthentication();
      final account = result == null ? null : await result;
      _account = account;
      return account != null;
    } on GoogleSignInException {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _ensureInitialized();
    _account = null;
    try {
      await _signIn.disconnect();
    } on GoogleSignInException {
      await _signIn.signOut();
    }
  }

  static String _describe(GoogleSignInException e) => switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'Login cancelado.',
        _ => 'Não foi possível entrar com o Google: '
            '${e.description ?? e.code.name}',
      };

  /// Drive API com um cliente HTTP autenticado. Com [interactive], pode
  /// mostrar a tela de permissão do Google.
  Future<drive.DriveApi> _api({required bool interactive}) async {
    final account = _account;
    if (account == null) {
      throw const DriveAuthException('Conecte sua conta Google primeiro.');
    }
    final authz = account.authorizationClient;
    var authorization = await authz.authorizationForScopes(scopes);
    if (authorization == null && interactive) {
      try {
        authorization = await authz.authorizeScopes(scopes);
      } on GoogleSignInException catch (e) {
        throw DriveAuthException(_describe(e));
      }
    }
    if (authorization == null) {
      throw const DriveAuthException('Permissão do Google Drive necessária.');
    }
    return drive.DriveApi(authorization.authClient(scopes: scopes));
  }

  /// Id da pasta "Mein Notizbuch", criada na primeira vez.
  Future<String> _folderId(drive.DriveApi api) async {
    final found = await api.files.list(
      q: "mimeType = '$_folderMime' and name = '$folderName' "
          'and trashed = false',
      spaces: 'drive',
      $fields: 'files(id)',
    );
    final existing = found.files;
    if (existing != null && existing.isNotEmpty) return existing.first.id!;

    final created = await api.files.create(
      drive.File()
        ..name = folderName
        ..mimeType = _folderMime,
      $fields: 'id',
    );
    return created.id!;
  }

  /// Envia o backup [data] como um arquivo .json novo.
  Future<DriveBackup> upload(
    Map<String, dynamic> data, {
    bool interactive = false,
  }) async {
    final api = await _api(interactive: interactive);
    final folder = await _folderId(api);
    final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(data));
    final now = DateTime.now();
    final file = await api.files.create(
      drive.File()
        ..name = 'notizbuch-${_stamp(now)}.json'
        ..parents = [folder]
        ..mimeType = 'application/json',
      uploadMedia: drive.Media(
        Stream<List<int>>.value(bytes),
        bytes.length,
        contentType: 'application/json',
      ),
      $fields: 'id,name,createdTime,size',
    );
    return _toBackup(file);
  }

  /// Backups da pasta, do mais novo para o mais antigo.
  Future<List<DriveBackup>> list({bool interactive = false}) async {
    final api = await _api(interactive: interactive);
    final folder = await _folderId(api);
    final result = await api.files.list(
      q: "'$folder' in parents and trashed = false",
      orderBy: 'createdTime desc',
      pageSize: 100,
      spaces: 'drive',
      $fields: 'files(id,name,createdTime,size)',
    );
    return [for (final f in result.files ?? const <drive.File>[]) _toBackup(f)];
  }

  /// Baixa e decodifica um backup.
  Future<Map<String, dynamic>> download(String fileId) async {
    final api = await _api(interactive: true);
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final text = await utf8.decodeStream(media.stream);
    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Mantém só os [keep] backups mais novos.
  Future<void> prune({int keep = 30}) async {
    final api = await _api(interactive: false);
    final all = await list();
    for (final old in all.skip(keep)) {
      await api.files.delete(old.id);
    }
  }

  static DriveBackup _toBackup(drive.File f) => DriveBackup(
        id: f.id!,
        name: f.name ?? 'backup.json',
        createdAt: (f.createdTime ?? DateTime.now()).toLocal(),
        sizeBytes: int.tryParse(f.size ?? ''),
      );

  static String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}-'
        '${two(d.hour)}${two(d.minute)}';
  }
}
