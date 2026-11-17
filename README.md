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
