# Mein Notizbuch

Caderno de vocabulário de alemão com método cromático, em Flutter 3
(Riverpod + Drift/SQLite + TTS do aparelho), para celular e tablet.

## Como rodar

Requisitos: Flutter 3.27 ou mais novo (`flutter --version`).

1. Gere as pastas nativas (android/ e ios/). O comando só cria o que falta e
   não sobrescreve `lib/`, `test/` nem o `pubspec.yaml`:

   ```bash
   cd ~/Downloads/meus/mein-notizbuch
   flutter create . --project-name mein_notizbuch --org com.seunome --platforms android,ios
   ```

2. Android 11+: libere o acesso ao serviço de voz. Em
   `android/app/src/main/AndroidManifest.xml`, dentro do bloco `<queries>`
   que o `flutter create` já gera, acrescente:

   ```xml
   <intent>
       <action android:name="android.intent.action.TTS_SERVICE" />
   </intent>
   ```

3. Instale as dependências e gere o código do banco (`app_database.g.dart`):

   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Teste e rode:

   ```bash
   flutter test
   flutter run
   ```

## Instalar no celular (Android)

Para usar o app no dia a dia, instale o build de **release** (mais rápido e
sem a faixa de debug).

1. No celular, ative as opções do desenvolvedor (toque 7 vezes em
   *Configurações › Sobre o telefone › Número da versão*) e, em
   *Opções do desenvolvedor*, ligue a **Depuração USB**. Conecte o cabo e
   aceite "Permitir depuração USB?".
2. Confira se o aparelho aparece:

   ```bash
   flutter devices
   ```

3. Instale de um destes jeitos:

   - Direto pelo cabo (compila, instala e abre):

     ```bash
     flutter run --release
     ```

   - Gerando o APK:

     ```bash
     flutter build apk --release
     ```

     O arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`.
     Instale com `flutter install` (cabo conectado) ou envie o arquivo para o
     celular e abra (o Android pede para permitir "fontes desconhecidas").

Por enquanto, o build de release é assinado com a chave de **debug**
(`signingConfig = signingConfigs.getByName("debug")` em
`android/app/build.gradle.kts`). Por isso:

- ele instala por cima de um build de debug sem perder os dados;
- o login Google (backup) funciona com o client Android do SHA-1 de debug.

Ao criar uma keystore de release própria (ex.: para a Play Store), o Android
não deixa instalar por cima do app atual: será preciso desinstalar, e os
dados do aparelho se perdem. Faça antes um backup no Drive para restaurar
depois, e cadastre um novo client Android com o SHA-1 da nova chave.

## Instalar no iPhone (conta Apple gratuita)

Precisa de um Mac com Xcode e do iPhone conectado por cabo.

1. Abra `ios/Runner.xcworkspace` no Xcode.
2. Em **Runner › Signing & Capabilities**, marque *Automatically manage
   signing* e escolha o seu **Personal Team** (a conta Apple gratuita). Se o
   Xcode disser que o identificador `com.brunodiedrich.meinNotizbuch` já
   está em uso, troque por outro único (ex.: acrescente um sufixo).
3. No terminal, na pasta do projeto:

   ```bash
   flutter run --release
   ```

4. Na primeira vez, o iPhone bloqueia o app: em *Ajustes › Geral › VPN e
   Gerenciamento de Dispositivos*, confie no seu certificado de
   desenvolvedor. Em iOS 16+, ative também o *Modo de Desenvolvedor*
   (*Ajustes › Privacidade e Segurança*).

Com a conta gratuita, o app instalado vale por **7 dias**: depois disso,
rode o `flutter run --release` de novo (os dados ficam no aparelho). No
iPhone, o lembrete diário funciona; o backup no Google Drive ainda é só para
Android.

## Pronúncia offline

O app usa a voz do próprio aparelho. Se o botão de áudio avisar que não há voz
em alemão, instale "Deutsch (Deutschland)" em Configurações › Acessibilidade ›
Texto para fala (Android) ou Ajustes › Acessibilidade › Conteúdo falado ›
Vozes (iOS).

## Estrutura

```text
lib/
├── main.dart
├── core/
│   ├── database/app_database.dart      tabela, consultas e fichas iniciais
│   ├── services/tts_service.dart       pronúncia em alemão
│   └── theme/
│       ├── app_icons.dart              ícones SVG do protótipo
│       ├── app_theme.dart              temas claro/escuro e paleta neutra
│       └── grammar_colors.dart         cores do método (com variantes escuras)
└── features/
    ├── vocabulary/
    │   ├── models/
    │   │   ├── grammar_type.dart       enum GrammarCategory
    │   │   └── word_parser.dart        detector de artigo e de infinitivo
    │   ├── providers/vocabulary_provider.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── flashcards_screen.dart
    │       │   └── add_word_screen.dart
    │       └── widgets/
    │           ├── flashcard_card.dart
    │           ├── pronunciation_box.dart
    │           └── tablet_notebook_view.dart
    └── review/
        ├── providers/review_quiz_provider.dart
        └── presentation/review_session_screen.dart
assets/fonts/                           Plus Jakarta Sans e Newsreader (OFL), DejaVu Sans Mono
```

## Visual

O app reproduz o protótipo HTML (Tailwind):

- Fontes: Plus Jakarta Sans na interface, Newsreader nas palavras e nos
  exemplos e DejaVu Sans Mono no IPA e no contador. A Newsreader vem em duas
  versões de tamanho óptico ("Display" para os títulos de 40 px), como o
  navegador faz automaticamente.
- Cores das classes: as do `tailwind.config` do protótipo, em
  `GrammarColors`. Chips de filtro: texto 800 e borda 100 do Tailwind, em
  `ChipColors`. Cinzas neutros: `AppPalette` (app_theme.dart).
- Ícones: os SVG do protótipo, em `app_icons.dart` (via flutter_svg).
- Cada classe tem suas seções: "presente" (verbo), "graus" (adjetivo) e a
  regra de regência (preposição).
- A navegação dá a volta (da última ficha para a primeira) e aceita as
  setas do teclado e a barra de espaço.

## Notas

- A classe gramatical é salva pelo nome (`textEnum`). Reordenar o enum é
  seguro; renomear um valor exige migração.
- Ao mudar colunas da tabela, aumente `schemaVersion` e escreva um
  `onUpgrade` no `MigrationStrategy`, senão o app já instalado quebra.
- O layout de caderno aberto (duas fichas) aparece a partir de 840 px de
  largura.

## Lembrete diário (palavra do dia)

Em **Ajustes** (engrenagem da tela inicial), "Palavra do dia" liga uma
notificação diária, no horário escolhido, com a palavra em alemão, a classe
gramatical e o significado. Tocar na notificação abre a ficha da palavra.

- Uma notificação agendada não escolhe a palavra na hora de aparecer: o app
  agenda os próximos 14 dias (cada dia com uma palavra) e refaz essa fila
  sempre que é aberto. Se o app ficar mais de 14 dias sem ser aberto, os
  lembretes param até a próxima abertura.
- O agendamento é inexato (`inexactAllowWhileIdle`): a notificação pode
  chegar alguns minutos depois do horário, mas o app não precisa da
  permissão de alarmes exatos.
- Hoje a palavra é sorteada (sem repetir até passar por todas). A escolha
  fica em `ReminderService.pickWords`, onde entra a repetição espaçada.
- O texto da notificação vem de `ReminderContent` e `translationOf`, o ponto
  para acrescentar outros idiomas de tradução.

No iOS, a permissão é pedida ao ligar o lembrete, e o `AppDelegate.swift`
registra o app como delegate do `UNUserNotificationCenter` (para mostrar a
notificação com o app aberto e tratar o toque).

Configuração no Android (já feita): permissões `POST_NOTIFICATIONS` e
`RECEIVE_BOOT_COMPLETED`, os receivers do `flutter_local_notifications` no
`AndroidManifest.xml`, o *core library desugaring* no `build.gradle.kts` e o
ícone `ic_notification` (silhueta da logo) em `res/drawable-*`.

## Exportar e importar (arquivo)

Em **Ajustes › Backup**, "Exportar para um arquivo" gera um `.json` com
palavras, decks e frases (o mesmo formato do backup no Drive) e abre o
"Salvar em…" do sistema: no iPhone, o app Arquivos (incluindo o iCloud
Drive); no Android, qualquer pasta ou provedor. "Importar de um arquivo"
mostra o que o arquivo contém e, depois de confirmar, substitui os dados do
aparelho. Funciona nas duas plataformas, sem login.

## Backup no Google Drive

O app envia um backup por dia (ao abrir) para a pasta **Mein Notizbuch** do
Google Drive da conta conectada, e guarda os 30 mais recentes. A tela fica no
ícone de nuvem da tela inicial. O escopo usado é `drive.file`: o app só
enxerga os arquivos que ele mesmo criou.

### Configuração (uma vez, no Google Cloud)

1. Em <https://console.cloud.google.com>, crie um projeto (ex.: "Mein Notizbuch").
2. **APIs e serviços › Biblioteca**: ative a **Google Drive API**.
3. **Tela de consentimento OAuth** (Google Auth Platform):
   - Público: **Externo**; status **Em teste**.
   - Adicione o seu e-mail em **Usuários de teste**.
   - Escopos: `.../auth/drive.file`.
4. **Credenciais › Criar credenciais › ID do cliente OAuth**, duas vezes:
   - Tipo **Android**: pacote `com.brunodiedrich.mein_notizbuch` e o
     **SHA-1** da chave de assinatura (veja "SHA-1 do build de debug"
     abaixo). Para o build de release, crie outro client Android com o
     SHA-1 da sua keystore de release.
   - Tipo **Aplicativo da Web**: nenhum campo extra (origens e URIs de
     redirecionamento ficam vazios). Copie o **ID do cliente**, que termina
     em `.apps.googleusercontent.com`.
5. Cole o ID do cliente **Web** em `lib/core/config/google_config.dart`
   (`googleServerClientId`).
6. `flutter pub get` e rode o app.

### SHA-1 do build de debug

O Flutter assina o build de debug com a keystore padrão do Android,
`~/.android/debug.keystore` (criada na primeira vez que você roda o app).
Para ver o SHA-1, use um dos comandos abaixo e copie a linha **SHA1**
(no formato `A1:B2:C3:…`):

```sh
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

ou, na pasta do projeto (use o bloco da variante `debug`):

```sh
cd android && ./gradlew signingReport
```

Cada computador tem a sua própria `debug.keystore`. Se você rodar o app
de outro computador, cadastre também o SHA-1 dele (mais um client
Android). Se o login falhar com erro de configuração ou "DEVELOPER_ERROR",
quase sempre é o SHA-1 ou o nome do pacote errados.

Enquanto o projeto estiver "Em teste", só os usuários de teste conseguem
entrar, e o Google pode pedir o login de novo a cada 7 dias.

