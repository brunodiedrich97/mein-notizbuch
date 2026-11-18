# Gera lib/l10n/app_strings*.dart a partir de tool/l10n/entries/*.py.
#
# Uso (na raiz do projeto): python3 tool/l10n/gen.py
#
# Cada entrada: e('chave', 'português', 'inglês', 'espanhol', 'parâmetros').
# O texto aceita interpolação do Dart ($nome, ${expr}). Um texto que começa
# com "=>" é uma expressão Dart (plurais, switch).
import glob, os, re
E=[]
def e(k, pt, en, es, p=''):
    E.append((k,p,pt,en,es))
for f in sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'entries', '*.py'))):
    exec(open(f).read(), {'e':e})
keys=[x[0] for x in E]
dups={k for k in keys if keys.count(k)>1}
assert not dups, dups
def lit(v):
    if v.startswith('=>'): return v[2:].strip()
    v=v.replace('\\','\\\\').replace("'","\\'").replace('\n','\\n')
    return "'"+v+"'"
def member(k,p,v,override):
    o='  @override\n' if override else ''
    if p: return f"\n{o}  String {k}({p}) =>\n      {lit(v)};\n"
    return f"\n{o}  String get {k} =>\n      {lit(v)};\n"
root=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'lib', 'l10n')
os.makedirs(root,exist_ok=True)
hdr='// GERADO por tool/l10n/gen.py: edite tool/l10n/entries, não este arquivo.\n// ignore_for_file: lines_longer_than_80_chars\n\n'
a=[hdr,"import 'app_strings_en.dart';\nimport 'app_strings_es.dart';\nimport 'app_strings_pt.dart';\n\n",
"/// Textos da interface nos idiomas do app (pt, en, es).\n///\n/// Use [tr] para o idioma ativo, escolhido em Ajustes.\nabstract class AppStrings {\n  const AppStrings();\n\n  /// Código do idioma (\"pt\", \"en\", \"es\").\n  String get code;\n\n  static const Map<String, AppStrings> all = {\n    'pt': AppStringsPt(),\n    'en': AppStringsEn(),\n    'es': AppStringsEs(),\n  };\n\n  static AppStrings current = const AppStringsPt();\n\n"]
for k,p,*_ in E:
    a.append(f"  String {k}({p});\n" if p else f"  String get {k};\n")
a.append("}\n\n/// Textos no idioma ativo da interface.\nAppStrings get tr => AppStrings.current;\n")
open(f'{root}/app_strings.dart','w').write(''.join(a))
for i,(lc,cls) in enumerate([('pt','AppStringsPt'),('en','AppStringsEn'),('es','AppStringsEs')]):
    b=[hdr,"import 'app_strings.dart';\n\n",f"class {cls} extends AppStrings {{\n  const {cls}();\n\n  @override\n  String get code => '{lc}';\n\n"]
    for k,p,*vals in E:
        b.append(member(k,p,vals[i],True))
    b.append('}\n')
    open(f'{root}/app_strings_{lc}.dart','w').write(''.join(b))
print(len(E),'entradas')
