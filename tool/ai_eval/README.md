# Teste dos modelos de IA (sugestões de ficha)

Compara modelos nas sugestões do cadastro: classe, IPA, aproximação na
língua nativa, dica fonética, formas e frase de exemplo. Só usa a
biblioteca padrão do Python 3.

## Rodar

```bash
# chaves das APIs (não salve em arquivo do projeto)
export ANTHROPIC_API_KEY=sk-ant-...
export OPENAI_API_KEY=sk-...
export GEMINI_API_KEY=...

python3 tool/ai_eval/eval.py --dry-run      # confere o prompt, sem gastar
python3 tool/ai_eval/eval.py --limit 3      # teste rápido (3 palavras)
python3 tool/ai_eval/eval.py                # tudo (37 palavras × modelos)
python3 tool/ai_eval/eval.py --only haiku   # um modelo só
```

O resultado vai para `tool/ai_eval/results/<data-hora>/` (fora do git):

- `report.html`: cada palavra com os modelos lado a lado e a armadilha
  que ela testa; no topo, latência e custo por 1.000 fichas.
- `results.csv`: uma linha por palavra e modelo, com as colunas
  "nota (0-5)" e "comentário" para avaliar numa planilha.
- `results.json`: tudo, para comparar rodadas.

## Arquivos

- `models.json`: modelos, ids e preços (confira nas páginas oficiais).
  `extra` acrescenta parâmetros à chamada, por exemplo
  `{"reasoning_effort": "minimal"}` (OpenAI) ou
  `{"generationConfig": {"thinkingConfig": {"thinkingBudget": 0}}}` (Gemini).
- `words.json`: palavras de teste, com o idioma de estudo, o nativo e a
  armadilha de cada uma.
- `prompt.py`: instruções e formato da resposta. É o mesmo texto que o
  servidor vai usar; ao mudar, aumente `PROMPT_VERSION`.

No Mac, se aparecer erro de certificado (SSL), rode uma vez o
"Install Certificates.command" da pasta do Python em Aplicativos.
