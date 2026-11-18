e('sortAz','A–Z','A–Z','A–Z')
e('sortRecent','Recentes','Recent','Recientes')
e('sortMistakes','Mais erradas','Most missed','Más falladas')
e('sortGender','Gênero','Gender','Género')
e('otherClasses','Outras classes','Other classes','Otras clases')
e('wordsCount',
  "=> switch (n) { 0 => 'Nenhuma palavra', 1 => '1 palavra', _ => '$n palavras' }",
  "=> switch (n) { 0 => 'No words', 1 => '1 word', _ => '$n words' }",
  "=> switch (n) { 0 => 'Ninguna palabra', 1 => '1 palabra', _ => '$n palabras' }",
  'int n')
e('words','Palavras','Words','Palabras')
e('filterByClass','Filtrar por classe','Filter by class','Filtrar por clase')
e('noWordsFoundFor','Nenhuma palavra encontrada para "$query".','No words found for "$query".','No se encontró ninguna palabra para "$query".','String query')
e('noWordsHereYet','Nenhuma palavra por aqui ainda.','No words here yet.','Aún no hay palabras aquí.')
e('searchIn','Buscar em $study ou $native','Search in $study or $native','Buscar en $study o $native','String study, String native')
# Classes gramaticais
e('deleteClassTitle','EXCLUIR CLASSE','DELETE CLASS','ELIMINAR CLASE')
e('deleteClassWarning',
  "=> switch (n) { 0 => 'Nenhuma palavra usa esta classe.', 1 => 'A palavra desta classe passa a ser \"$other\".', _ => 'As $n palavras desta classe passam a ser \"$other\".' }",
  "=> switch (n) { 0 => 'No words use this class.', 1 => 'The word in this class becomes \"$other\".', _ => 'The $n words in this class become \"$other\".' }",
  "=> switch (n) { 0 => 'Ninguna palabra usa esta clase.', 1 => 'La palabra de esta clase pasa a ser \"$other\".', _ => 'Las $n palabras de esta clase pasan a ser \"$other\".' }",
  'int n, String other')
e('grammarClassesCaps','CLASSES GRAMATICAIS','WORD CLASSES','CLASES GRAMATICALES')
e('newClass','Nova classe','New class','Nueva clase')
e('editClass','Editar classe','Edit class','Editar clase')
e('deleteClass','Excluir classe','Delete class','Eliminar clase')
e('colorCaps','COR','COLOR','COLOR')
e('classPlaceholder','Classe','Class','Clase')
e('similarColorWarning','Parecida com "$name". Escolha um tom mais distante para não confundir as classes.','Similar to "$name". Pick a more distinct shade so the classes don\'t get mixed up.','Parecida a "$name". Elige un tono más distinto para no confundir las clases.','String name')
e('createClass','Criar classe','Create class','Crear clase')
e('nameCaps','NOME','NAME','NOMBRE')
e('classNameHint','Conjunção, Pronome, Expressão…','Conjunction, Pronoun, Phrase…','Conjunción, Pronombre, Expresión…')
e('darkTheme','TEMA ESCURO','DARK THEME','TEMA OSCURO')
e('lightTheme','TEMA CLARO','LIGHT THEME','TEMA CLARO')
e('builtInNoun','Substantivo','Noun','Sustantivo')
e('builtInMasc','Substantivo masculino ($article)','Masculine noun ($article)','Sustantivo masculino ($article)','String article')
e('builtInFem','Substantivo feminino ($article)','Feminine noun ($article)','Sustantivo femenino ($article)','String article')
e('builtInNeut','Substantivo neutro ($article)','Neuter noun ($article)','Sustantivo neutro ($article)','String article')
e('builtInVerb','Verbo','Verb','Verbo')
e('builtInAdjective','Adjetivo','Adjective','Adjetivo')
e('builtInAdverb','Advérbio','Adverb','Adverbio')
e('builtInPreposition','Preposição','Preposition','Preposición')
e('builtInOther','Outros','Other','Otros')
e('settingsCaps','AJUSTES','SETTINGS','AJUSTES')
e('myClassesCaps','MINHAS CLASSES','MY CLASSES','MIS CLASES')
e('classesCount',
  "=> n == 1 ? '1 classe' : '$n classes'",
  "=> n == 1 ? '1 class' : '$n classes'",
  "=> n == 1 ? '1 clase' : '$n clases'",
  'int n')
e('customClassesExplanation','Classes novas funcionam como "outros": tradução, pronúncia e exemplo, sem campos especiais.','New classes work like "other": translation, pronunciation and example, with no special fields.','Las clases nuevas funcionan como "otros": traducción, pronunciación y ejemplo, sin campos especiales.')
e('fromTheMethodCaps','DO MÉTODO','BUILT-IN','DEL MÉTODO')
e('fixedColors','cores fixas','fixed colors','colores fijos')
# Widget
e('addWidgetCaps','ADICIONAR WIDGET','ADD WIDGET','AÑADIR WIDGET')
e('widgetStep1','Toque e segure num espaço vazio da tela inicial.','Touch and hold an empty spot on the home screen.','Mantén pulsado un espacio vacío de la pantalla de inicio.')
e('widgetStep2','Toque em "Widgets".','Tap "Widgets".','Toca "Widgets".')
e('widgetStep3','Procure "Mein Notizbuch" e arraste "Palavra do dia" para a tela.','Find "Mein Notizbuch" and drag "Word of the day" onto the screen.','Busca "Mein Notizbuch" y arrastra "Palabra del día" a la pantalla.')
e('gotIt','Entendi','Got it','Entendido')
e('widgetInviteTitle','Palavra do dia na tela inicial','Word of the day on your home screen','Palabra del día en la pantalla de inicio')
e('widgetInviteText','Uma palavra nova por dia, com a classe e o significado, sem abrir o app.','A new word every day, with its class and meaning, without opening the app.','Una palabra nueva cada día, con su clase y significado, sin abrir la app.')
e('notNow','Agora não','Not now','Ahora no')
e('addWidget','Adicionar widget','Add widget','Añadir widget')
