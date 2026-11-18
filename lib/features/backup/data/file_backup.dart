import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/app_strings.dart';

/// Backup como arquivo .json escolhido pelo usuário: no iPhone, o app
/// Arquivos (incluindo o iCloud Drive); no Android, qualquer pasta ou
/// provedor (Downloads, Google Drive…).
class FileBackup {
  FileBackup._();

  static String _fileName(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'notizbuch-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  /// Abre o "Salvar em…" do sistema com todos os dados. Retorna `false`
  /// se o usuário cancelar.
  static Future<bool> export(AppDatabase db) async {
    final data = await db.exportData();
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
    );
    final path = await FilePicker.platform.saveFile(
      dialogTitle: tr.exportBackupTitle,
      fileName: _fileName(DateTime.now()),
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    return path != null;
  }

  /// Abre o seletor de arquivos e lê o backup escolhido. Retorna `null` se
  /// o usuário cancelar. Lança [FormatException] se não for um JSON válido.
  /// Não grava nada: use [AppDatabase.importData] depois de confirmar.
  static Future<Map<String, dynamic>?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: tr.importBackupTitle,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return null;
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(tr.notABackupFile);
    }
    return decoded;
  }
}
