/// De onde veio uma frase de "Minhas frases".
///
/// O banco salva o NOME de cada valor (via `textEnum`), então reordenar
/// esta lista é seguro. Só não renomeie um valor existente sem migração.
enum SentenceSource {
  /// Escrita livremente a partir da ficha.
  free,

  /// Salva depois do exercício de tradução reversa.
  translation,
}
