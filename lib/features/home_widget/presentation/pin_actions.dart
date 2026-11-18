import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/app_strings.dart';
import '../providers/pinned_word_provider.dart';

/// Fixa [word] no widget, ou solta se ela já estiver fixada. Mostra um
/// aviso com "Desfazer", que volta à escolha anterior.
Future<void> togglePinnedWord(
  BuildContext context,
  WidgetRef ref,
  WordEntry word,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final previous = ref.read(pinnedWordProvider)?.id;
  final pin = previous != word.id;
  await setPinnedWord(ref, pin ? word.id : null);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          pin ? tr.wordPinned(word.germanWord) : tr.wordUnpinned,
        ),
        action: SnackBarAction(
          label: tr.undo,
          onPressed: () => setPinnedWord(ref, previous),
        ),
      ),
    );
}
