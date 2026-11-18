e('notebookEmptyShort','Seu Notizbuch ainda está vazio','Your Notizbuch is still empty','Tu Notizbuch aún está vacío')
e('decksCount',
  "=> n == 1 ? '1 deck' : '$n decks'",
  "=> n == 1 ? '1 deck' : '$n decks'",
  "=> n == 1 ? '1 mazo' : '$n mazos'",
  'int n')
e('cardsInDecks','$cards em $decks','$cards in $decks','$cards en $decks','String cards, String decks')
e('reviewAll','Revisar tudo','Review all','Repasar todo')
e('quizAllDecks','Quiz com todos os decks','Quiz with all decks','Quiz con todos los mazos')
e('needsTwoCards','Precisa de 2 fichas','Needs 2 cards','Necesita 2 fichas')
e('add','Adicionar','Add','Añadir')
e('newWord','Nova palavra','New word','Nueva palabra')
e('myDecks','MEUS DECKS','MY DECKS','MIS MAZOS')
e('latestWords','ÚLTIMAS PALAVRAS','LATEST WORDS','ÚLTIMAS PALABRAS')
e('seeAll','Ver todas','See all','Ver todas')
e('deckDeleted','Deck "$deck" excluído.','Deck "$deck" deleted.','Mazo "$deck" eliminado.','String deck')
e('deckCaps','DECK','DECK','MAZO')
e('studyCards','Estudar fichas','Study cards','Estudiar fichas')
e('reviewDeck','Revisar deck','Review deck','Repasar mazo')
e('write','Escrever','Write','Escribir')
e('wordsCaps','PALAVRAS','WORDS','PALABRAS')
e('addPlus','+ Adicionar','+ Add','+ Añadir')
e('deckNoWords','Nenhuma palavra neste deck ainda. Toque em "$button" para cadastrar a primeira.','No words in this deck yet. Tap "$button" to add the first one.','Aún no hay palabras en este mazo. Toca "$button" para registrar la primera.','String button')
e('seeAllWords','Ver todas as $n palavras','See all $n words','Ver las $n palabras','int n')
e('deleteDeck','Excluir deck','Delete deck','Eliminar mazo')
e('deleteDeckWarning',
  "=> switch (n) { 0 => 'O deck está vazio. Essa ação não pode ser desfeita.', 1 => 'A palavra deste deck vai para o deck \"$general\". Essa ação não pode ser desfeita.', _ => 'As $n palavras deste deck vão para o deck \"$general\". Essa ação não pode ser desfeita.' }",
  "=> switch (n) { 0 => 'The deck is empty. This can\\'t be undone.', 1 => 'The word in this deck moves to the \"$general\" deck. This can\\'t be undone.', _ => 'The $n words in this deck move to the \"$general\" deck. This can\\'t be undone.' }",
  "=> switch (n) { 0 => 'El mazo está vacío. Esta acción no se puede deshacer.', 1 => 'La palabra de este mazo pasa al mazo \"$general\". Esta acción no se puede deshacer.', _ => 'Las $n palabras de este mazo pasan al mazo \"$general\". Esta acción no se puede deshacer.' }",
  'int n, String general')
e('deleteDeckTitle','EXCLUIR DECK','DELETE DECK','ELIMINAR MAZO')
e('newDeck','Novo deck','New deck','Nuevo mazo')
e('createDeckFailed','Não foi possível criar o deck: $error','Could not create the deck: $error','No se pudo crear el mazo: $error','Object error')
e('newDeckCaps','NOVO DECK','NEW DECK','NUEVO MAZO')
e('nameIn','Nome em $language','Name in $language','Nombre en $language','String language')
e('nameInOptional','Nome em $language (opcional)','Name in $language (optional)','Nombre en $language (opcional)','String language')
e('giveDeckName','Dê um nome ao deck.','Give the deck a name.','Ponle un nombre al mazo.')
e('iconCaps','ÍCONE','ICON','ICONO')
e('createDeck','Criar deck','Create deck','Crear mazo')
