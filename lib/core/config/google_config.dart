import 'dart:io' show Platform;

/// Configuração do login Google (backup no Drive).
///
/// [googleServerClientId] é o ID do client OAuth do tipo **Aplicativo da
/// Web** criado no Google Cloud (não o client Android). O client Android
/// também precisa existir no mesmo projeto, com o nome do pacote
/// `com.brunodiedrich.mein_notizbuch` e o SHA-1 da chave de assinatura,
/// mas o ID dele não entra no código.
///
/// Passo a passo no README, seção "Backup no Google Drive".
const String googleServerClientId =
    '254788562202-g8v4gp9oq25ncr3euvdnj5pi8g3grsiu.apps.googleusercontent.com';

/// `true` quando o client ID acima já foi preenchido.
bool get isGoogleConfigured => !googleServerClientId.startsWith('COLE_AQUI');

/// O backup no Drive só está configurado para Android. No iOS, o login
/// Google precisa de um client iOS e do esquema de URL no Info.plist.
bool get isDriveBackupSupported => Platform.isAndroid;
