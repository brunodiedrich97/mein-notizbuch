e('writeEyebrow','ESCREVER','WRITE','ESCRIBIR')
e('rightCount','certas','right','correctas')
e('toReviewCount','para rever','to review','para repasar')
e('knewCount','sabia','knew it','la sabía')
e('notYetCount','ainda não','not yet','todavía no')
e('writeIn','ESCREVA EM $language','WRITE IN $language','ESCRIBE EN $language','String language')
e('writeSentenceIn','Escreva a frase em $language…','Write the sentence in $language…','Escribe la frase en $language…','String language')
e('showAnswer','Mostrar resposta','Show answer','Mostrar respuesta')
e('check','Conferir','Check','Comprobar')
e('acceptAsRight','Considerar certa','Count as right','Dar por correcta')
e('finish','Concluir','Finish','Terminar')
e('nextFem','Próxima','Next','Siguiente')
e('reverseTranslation','Tradução reversa','Reverse translation','Traducción inversa')
e('useWord','use: $word','use: $word','usa: $word','String word')
e('thisIsTheAnswer','Esta é a resposta','This is the answer','Esta es la respuesta')
e('perfect','Perfeito!','Perfect!','¡Perfecto!')
e('acceptedAsRight','Considerada certa','Counted as right','Dada por correcta')
e('differences',
  "=> n == 1 ? 'Quase! 1 diferença' : '$n diferenças'",
  "=> n == 1 ? 'Almost! 1 difference' : '$n differences'",
  "=> n == 1 ? '¡Casi! 1 diferencia' : '$n diferencias'",
  'int n')
e('yourAnswer','SUA RESPOSTA','YOUR ANSWER','TU RESPUESTA')
e('expectedAnswer','RESPOSTA ESPERADA','EXPECTED ANSWER','RESPUESTA ESPERADA')
e('savedInMySentences','Salva em "Minhas frases"','Saved in "My sentences"','Guardada en "Mis frases"')
e('saveCorrectSentence','Salvar a frase correta em "Minhas frases"','Save the correct sentence in "My sentences"','Guardar la frase correcta en "Mis frases"')
e('noExamplesInNotebook','Nenhuma ficha tem exemplo com tradução. Cadastre a frase de exemplo e a tradução dela em "$screen".','No card has an example with a translation. Add an example sentence and its translation in "$screen".','Ninguna ficha tiene un ejemplo con traducción. Registra la frase de ejemplo y su traducción en "$screen".','String screen')
e('noExamplesInDeck','Nenhuma ficha do deck "$deck" tem exemplo com tradução. Cadastre a frase de exemplo e a tradução dela em "$screen".','No card in the "$deck" deck has an example with a translation. Add an example sentence and its translation in "$screen".','Ninguna ficha del mazo "$deck" tiene un ejemplo con traducción. Registra la frase de ejemplo y su traducción en "$screen".','String deck, String screen')
e('sentenceSaved','Frase salva na ficha.','Sentence saved to the card.','Frase guardada en la ficha.')
e('writeASentenceWith','ESCREVA UMA FRASE COM','WRITE A SENTENCE WITH','ESCRIBE UNA FRASE CON')
e('writeHereIn','Escreva aqui em $language…','Write here in $language…','Escribe aquí en $language…','String language')
e('sentenceUsesWord','A frase usa "$word".','The sentence uses "$word".','La frase usa "$word".','String word')
e('sentenceDoesNotUseWord','A frase ainda não usa "$word".','The sentence doesn\'t use "$word" yet.','La frase aún no usa "$word".','String word')
e('translationOptional','Tradução (opcional)','Translation (optional)','Traducción (opcional)')
e('whatTheSentenceMeans','O que a frase quer dizer','What the sentence means','Lo que quiere decir la frase')
e('cardExampleToCompare','Exemplo da ficha, para comparar','Card example, to compare','Ejemplo de la ficha, para comparar')
e('saveToCard','Salvar na ficha','Save to card','Guardar en la ficha')
e('deleteSentenceTitle','EXCLUIR FRASE','DELETE SENTENCE','ELIMINAR FRASE')
e('deleteSentenceWarning','A frase sai de "Minhas frases". A ficha não muda.','The sentence is removed from "My sentences". The card doesn\'t change.','La frase sale de "Mis frases". La ficha no cambia.')
# Correção
e('contractionRequired','"$word" = $prep + $article. Em $language, essa junção é obrigatória.','"$word" = $prep + $article. In $language, this contraction is required.','"$word" = $prep + $article. En $language, esta contracción es obligatoria.','String word, String prep, String article, String language')
e('articleMismatch','Artigo: o esperado é "$want", e não "$got". Confira o caso (nominativo, acusativo, dativo) e o gênero da palavra.','Article: expected "$want", not "$got". Check the case (nominative, accusative, dative) and the gender of the word.','Artículo: se esperaba "$want", no "$got". Revisa el caso (nominativo, acusativo, dativo) y el género de la palabra.','String want, String got')
e('writtenLowercase','"$word" é escrita com minúscula.','"$word" is written in lowercase.','"$word" se escribe con minúscula.','String word')
e('nounCapitalized','"$word" começa com maiúscula: em $language, todo substantivo é escrito com inicial maiúscula.','"$word" starts with a capital letter: in $language, every noun is capitalized.','"$word" empieza con mayúscula: en $language, todo sustantivo se escribe con mayúscula inicial.','String word, String language')
e('startsCapitalized','"$word" começa com maiúscula.','"$word" starts with a capital letter.','"$word" empieza con mayúscula.','String word')
e('umlautMismatch','Trema: o esperado é "$want", e não "$got".','Umlaut: expected "$want", not "$got".','Diéresis: se esperaba "$want", no "$got".','String want, String got')
# Resumo da sessão
e('sessionFinishedCaps','SESSÃO CONCLUÍDA','SESSION COMPLETE','SESIÓN TERMINADA')
e('youStudied',
  "=> deck == null ? 'Você estudou ${cardsCount(n)}.' : 'Você estudou ${cardsCount(n)} do deck $deck.'",
  "=> deck == null ? 'You studied ${cardsCount(n)}.' : 'You studied ${cardsCount(n)} from the $deck deck.'",
  "=> deck == null ? 'Estudiaste ${cardsCount(n)}.' : 'Estudiaste ${cardsCount(n)} del mazo $deck.'",
  'int n, String? deck')
e('youPracticed',
  "=> deck == null ? 'Você praticou ${cardsCount(n)}.' : 'Você praticou ${cardsCount(n)} do deck $deck.'",
  "=> deck == null ? 'You practiced ${cardsCount(n)}.' : 'You practiced ${cardsCount(n)} from the $deck deck.'",
  "=> deck == null ? 'Practicaste ${cardsCount(n)}.' : 'Practicaste ${cardsCount(n)} del mazo $deck.'",
  'int n, String? deck')
e('toReviewCaps','PARA REVER','TO REVIEW','PARA REPASAR')
e('newSession','Nova sessão','New session','Nueva sesión')
e('cardsCount',
  "=> n == 1 ? '1 ficha' : '$n fichas'",
  "=> n == 1 ? '1 card' : '$n cards'",
  "=> n == 1 ? '1 ficha' : '$n fichas'",
  'int n')
