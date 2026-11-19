#!/usr/bin/env python3
"""Compara modelos de IA nas sugestões de ficha (IPA, aproximação, dica,
classe, exemplo...). Só usa a biblioteca padrão do Python.

Uso (na raiz do projeto):
    export ANTHROPIC_API_KEY=...   OPENAI_API_KEY=...   GEMINI_API_KEY=...
    python3 tool/ai_eval/eval.py                  # todos os casos e modelos
    python3 tool/ai_eval/eval.py --limit 5        # só os 5 primeiros casos
    python3 tool/ai_eval/eval.py --only haiku     # só um modelo
    python3 tool/ai_eval/eval.py --dry-run        # mostra o prompt, sem chamar

Saída em tool/ai_eval/results/<data-hora>/: report.html (lado a lado, para
ler), results.csv (para dar notas numa planilha) e results.json.
"""

import argparse
import csv
import html
import json
import os
import statistics
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import prompt  # noqa: E402

TIMEOUT = 60
MAX_OUTPUT_TOKENS = 800


# ---------------------------------------------------------------- HTTP

def post_json(url, headers, body):
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        url, data=data, method='POST',
        headers={'content-type': 'application/json', **headers},
    )
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
                return json.loads(resp.read())
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors='replace')[:500]
            # Limite de taxa ou erro do servidor: espera e tenta de novo.
            if e.code in (429, 500, 502, 503, 529) and attempt < 2:
                time.sleep(2 * (attempt + 1))
                continue
            raise RuntimeError(f'HTTP {e.code}: {detail}') from None


def deep_merge(base, extra):
    for k, v in (extra or {}).items():
        if isinstance(v, dict) and isinstance(base.get(k), dict):
            deep_merge(base[k], v)
        else:
            base[k] = v
    return base


def env(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f'defina a variável de ambiente {name}')
    return value


# ------------------------------------------------------------ provedores

def call_anthropic(model, system, user, schema, extra):
    body = deep_merge({
        'model': model,
        'max_tokens': MAX_OUTPUT_TOKENS,
        'temperature': 0.2,
        'system': system,
        'messages': [{'role': 'user', 'content': user}],
        # Ferramenta obrigatória: a resposta sai como JSON no formato dado.
        'tools': [{
            'name': 'save_card',
            'description': 'Save the flashcard fields.',
            'input_schema': schema,
        }],
        'tool_choice': {'type': 'tool', 'name': 'save_card'},
    }, extra)
    r = post_json('https://api.anthropic.com/v1/messages', {
        'x-api-key': env('ANTHROPIC_API_KEY'),
        'anthropic-version': '2023-06-01',
    }, body)
    card = next(
        (c['input'] for c in r.get('content', []) if c.get('type') == 'tool_use'),
        None,
    )
    if card is None:
        raise RuntimeError(f'sem tool_use na resposta: {json.dumps(r)[:300]}')
    u = r.get('usage', {})
    return card, u.get('input_tokens', 0), u.get('output_tokens', 0)


def call_openai(model, system, user, schema, extra):
    body = deep_merge({
        'model': model,
        'max_completion_tokens': MAX_OUTPUT_TOKENS,
        'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
        ],
        'response_format': {
            'type': 'json_schema',
            'json_schema': {'name': 'card', 'strict': True, 'schema': schema},
        },
    }, extra)
    r = post_json('https://api.openai.com/v1/chat/completions', {
        'authorization': f'Bearer {env("OPENAI_API_KEY")}',
    }, body)
    text = r['choices'][0]['message'].get('content') or ''
    u = r.get('usage', {})
    return parse_json(text), u.get('prompt_tokens', 0), u.get('completion_tokens', 0)


def call_gemini(model, system, user, schema, extra):
    body = deep_merge({
        'systemInstruction': {'parts': [{'text': system}]},
        'contents': [{'role': 'user', 'parts': [{'text': user}]}],
        'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': MAX_OUTPUT_TOKENS,
            'responseMimeType': 'application/json',
        },
    }, extra)
    url = ('https://generativelanguage.googleapis.com/v1beta/models/'
           f'{model}:generateContent')
    r = post_json(url, {'x-goog-api-key': env('GEMINI_API_KEY')}, body)
    parts = r['candidates'][0]['content']['parts']
    text = ''.join(p.get('text', '') for p in parts if not p.get('thought'))
    u = r.get('usageMetadata', {})
    out = u.get('candidatesTokenCount', 0) + u.get('thoughtsTokenCount', 0)
    return parse_json(text), u.get('promptTokenCount', 0), out


PROVIDERS = {
    'anthropic': call_anthropic,
    'openai': call_openai,
    'gemini': call_gemini,
}


def parse_json(text):
    text = text.strip()
    start, end = text.find('{'), text.rfind('}')
    if start < 0 or end < 0:
        raise RuntimeError(f'resposta sem JSON: {text[:200]}')
    return json.loads(text[start:end + 1])


def problems(card, study):
    """Erros de formato (não de conteúdo, que você avalia no relatório)."""
    found = []
    for f in prompt.FIELDS:
        if f not in card:
            found.append(f'falta "{f}"')
    if card.get('category') not in prompt.STUDY[study]['categories']:
        found.append(f'classe inválida: {card.get("category")}')
    for f in prompt.REQUIRED_TEXT:
        if not (card.get(f) or '').strip():
            found.append(f'"{f}" vazio')
    ipa = card.get('ipa') or ''
    if ipa[:1] in '[/' or ipa[-1:] in ']/':
        found.append('IPA com colchetes ou barras')
    return found


# ------------------------------------------------------------ execução

def run(args):
    with open(os.path.join(HERE, 'models.json')) as f:
        models = [m for m in json.load(f)['models'] if m.get('enabled', True)]
    if args.only:
        wanted = set(args.only.split(','))
        models = [m for m in models if m['id'] in wanted]
    with open(os.path.join(HERE, 'words.json')) as f:
        cases = json.load(f)['cases']
    if args.study:
        cases = [c for c in cases if c['study'] == args.study]
    if args.limit:
        cases = cases[:args.limit]

    if args.dry_run:
        c = cases[0]
        print(prompt.system_prompt(c['study'], c['native']))
        print('\n' + prompt.user_prompt(c['word']))
        print(f'\n{len(cases)} casos × {len(models)} modelos =',
              len(cases) * len(models), 'chamadas')
        return

    results = []
    total = len(cases) * len(models)
    n = 0
    for c in cases:
        system = prompt.system_prompt(c['study'], c['native'])
        user = prompt.user_prompt(c['word'])
        schema = prompt.schema(c['study'])
        for m in models:
            n += 1
            print(f'[{n}/{total}] {m["id"]:<14} {c["word"]} '
                  f'({c["study"]}→{c["native"]})', end=' ', flush=True)
            row = {**c, 'model': m['id']}
            t0 = time.monotonic()
            try:
                card, tin, tout = PROVIDERS[m['provider']](
                    m['model'], system, user, schema, m.get('extra'))
                row.update(card=card, problems=problems(card, c['study']),
                           tokens_in=tin, tokens_out=tout,
                           cost=tin * m['price_in'] / 1e6
                           + tout * m['price_out'] / 1e6)
                print('ok' if not row['problems'] else
                      f'formato: {"; ".join(row["problems"])}')
            except Exception as e:  # noqa: BLE001
                row.update(card=None, error=str(e), problems=[],
                           tokens_in=0, tokens_out=0, cost=0)
                print(f'ERRO: {e}')
            row['latency_ms'] = round((time.monotonic() - t0) * 1000)
            results.append(row)

    out = os.path.join(HERE, 'results', datetime.now().strftime('%Y%m%d-%H%M%S'))
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, 'results.json'), 'w') as f:
        json.dump({'prompt_version': prompt.PROMPT_VERSION,
                   'models': models, 'results': results},
                  f, ensure_ascii=False, indent=1)
    write_csv(os.path.join(out, 'results.csv'), results)
    summary = summarize(models, results)
    write_html(os.path.join(out, 'report.html'), models, cases, results, summary)
    print('\nResumo:')
    for s in summary:
        print(f'  {s["id"]:<14} ok {s["ok"]}/{s["total"]}  '
              f'formato {s["format_issues"]}  erros {s["errors"]}  '
              f'latência mediana {s["latency_med"]} ms  '
              f'US$ {s["per_1000"]:.3f} por 1.000 fichas')
    print(f'\nRelatório: {os.path.join(out, "report.html")}')


def summarize(models, results):
    rows = []
    for m in models:
        mine = [r for r in results if r['model'] == m['id']]
        done = [r for r in mine if r.get('card') is not None]
        lat = [r['latency_ms'] for r in done]
        cost = sum(r['cost'] for r in done)
        rows.append({
            'id': m['id'],
            'model': m['model'],
            'total': len(mine),
            'ok': sum(1 for r in done if not r['problems']),
            'format_issues': sum(1 for r in done if r['problems']),
            'errors': len(mine) - len(done),
            'latency_med': round(statistics.median(lat)) if lat else 0,
            'latency_max': max(lat) if lat else 0,
            'tokens_in': round(statistics.mean([r['tokens_in'] for r in done])) if done else 0,
            'tokens_out': round(statistics.mean([r['tokens_out'] for r in done])) if done else 0,
            'per_1000': cost / len(done) * 1000 if done else 0,
        })
    return rows


def write_csv(path, results):
    fields = ['word', 'study', 'native', 'model', *prompt.FIELDS,
              'problems', 'error', 'latency_ms', 'tokens_in', 'tokens_out',
              'cost', 'nota (0-5)', 'comentário']
    with open(path, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for r in results:
            card = r.get('card') or {}
            w.writerow({
                'word': r['word'], 'study': r['study'], 'native': r['native'],
                'model': r['model'],
                **{k: card.get(k) for k in prompt.FIELDS},
                'problems': '; '.join(r['problems']),
                'error': r.get('error', ''),
                'latency_ms': r['latency_ms'],
                'tokens_in': r['tokens_in'], 'tokens_out': r['tokens_out'],
                'cost': f'{r["cost"]:.6f}',
            })


def write_html(path, models, cases, results, summary):
    e = html.escape
    ids = [m['id'] for m in models]
    parts = [f"""<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">
<title>Sugestões de ficha: comparação de modelos</title><style>
body{{font:14px/1.45 -apple-system,Segoe UI,Roboto,sans-serif;margin:24px;color:#111827;background:#FCFBF9}}
h1{{font-size:22px}} h2{{font-size:17px;margin:28px 0 4px}}
.trap{{color:#6B7280;margin:0 0 8px}}
table{{border-collapse:collapse;width:100%;background:#fff}}
th,td{{border:1px solid #E5E7EB;padding:6px 8px;vertical-align:top;text-align:left}}
th{{background:#F3F4F6;font-weight:600}} td.f{{color:#6B7280;white-space:nowrap;width:1%}}
.null{{color:#C0C4CC}} .bad{{background:#FEF2F2;color:#991B1B}} .num{{text-align:right}}
</style></head><body>
<h1>Sugestões de ficha: comparação de modelos</h1>
<p>Prompt versão {prompt.PROMPT_VERSION} · {len(cases)} palavras · {datetime.now():%d/%m/%Y %H:%M}</p>
<table><tr><th>Modelo</th><th>OK</th><th>Formato</th><th>Erros</th>
<th>Latência mediana</th><th>Latência máx.</th><th>Tokens (entrada/saída)</th><th>US$ por 1.000 fichas</th></tr>"""]
    for s in summary:
        parts.append(
            f'<tr><td><b>{e(s["id"])}</b><br><span class="null">{e(s["model"])}</span></td>'
            f'<td class="num">{s["ok"]}/{s["total"]}</td><td class="num">{s["format_issues"]}</td>'
            f'<td class="num">{s["errors"]}</td><td class="num">{s["latency_med"]} ms</td>'
            f'<td class="num">{s["latency_max"]} ms</td>'
            f'<td class="num">{s["tokens_in"]} / {s["tokens_out"]}</td>'
            f'<td class="num">{s["per_1000"]:.3f}</td></tr>')
    parts.append('</table>')

    by_key = {(r['word'], r['study'], r['native'], r['model']): r for r in results}
    for c in cases:
        parts.append(f'<h2>{e(c["word"])} <span class="null">({c["study"]}→{c["native"]})</span></h2>'
                     f'<p class="trap">Armadilha: {e(c.get("trap", ""))}</p>')
        parts.append('<table><tr><th></th>' + ''.join(f'<th>{e(i)}</th>' for i in ids) + '</tr>')
        rows = {i: by_key.get((c['word'], c['study'], c['native'], i)) for i in ids}
        for f in prompt.FIELDS:
            cells = []
            for i in ids:
                r = rows[i]
                if r is None:
                    cells.append('<td></td>')
                elif r.get('card') is None:
                    cells.append(f'<td class="bad">{e(r.get("error", "erro"))[:200]}</td>'
                                 if f == 'category' else '<td></td>')
                else:
                    v = r['card'].get(f)
                    cells.append('<td class="null">—</td>' if v in (None, '')
                                 else f'<td>{e(str(v))}</td>')
            parts.append(f'<tr><td class="f">{f}</td>{"".join(cells)}</tr>')
        notes = [f'{i}: {"; ".join(rows[i]["problems"])}'
                 for i in ids if rows[i] and rows[i]['problems']]
        if notes:
            parts.append(f'<tr><td class="f">formato</td><td class="bad" colspan="{len(ids)}">'
                         f'{e(" | ".join(notes))}</td></tr>')
        parts.append('</table>')
    parts.append('</body></html>')
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(parts))


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--only', help='ids de models.json separados por vírgula')
    ap.add_argument('--study', choices=sorted(prompt.STUDY), help='só um idioma de estudo')
    ap.add_argument('--limit', type=int, help='só os N primeiros casos')
    ap.add_argument('--dry-run', action='store_true', help='mostra o prompt sem chamar as APIs')
    run(ap.parse_args())
