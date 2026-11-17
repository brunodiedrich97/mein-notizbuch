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
bool get isGoogleConfigured => !googleServerClientId.startsWith('254788562202');
