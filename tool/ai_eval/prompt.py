"""Instruções e formato da resposta das sugestões de ficha.

O mesmo texto será usado depois no servidor (Cloudflare Worker). Ao mudar
as instruções, aumente PROMPT_VERSION: o cache do servidor usa a versão na
chave, então respostas antigas deixam de valer.
"""

PROMPT_VERSION = 1

STUDY = {
    'de': {
        'name': 'German',
        'categories': [
            'masculineNoun', 'feminineNoun', 'neuterNoun', 'verb',
            'adjective', 'adverb', 'preposition', 'other',
        ],
        'rules': (
            '- Nouns: "lemma" is the singular WITH its definite article '
            '("der Hund"); category is masculineNoun/feminineNoun/neuterNoun. '
            'If the user typed a plural or no article, still return the '
            'singular with the correct article.\n'
            '- "plural": with article ("die Hunde"); use the same form if '
            'invariable ("die Mädchen").\n'
            '- Verbs: "lemma" is the infinitive; "verbForms" = Präteritum · '
            'Perfekt WITH auxiliary ("ging · ist gegangen"). "tagDetail": '
            'regular / irregular / separable, in the native language.\n'
            '- Adjectives/adverbs: "degrees" = "schön → schöner → am '
            'schönsten" when they exist.\n'
            '- Prepositions: "tagDetail" = the case (in the native language) '
            'and "prepositionCase" = a one-line rule in the native language '
            'listing related prepositions.\n'
            '- Conjunctions, pronouns, particles: category "other".'
        ),
    },
    'en': {
        'name': 'English',
        'categories': [
            'noun', 'verb', 'adjective', 'adverb', 'preposition', 'other',
        ],
        'rules': (
            '- Nouns: "lemma" without article ("dog"); category "noun".\n'
            '- "plural": the plural form ("dogs", "mice").\n'
            '- Verbs: "lemma" with "to" ("to go"); "verbForms" = past · past '
            'participle ("went · gone"). "tagDetail": regular / irregular, '
            'in the native language.\n'
            '- Adjectives/adverbs: "degrees" = "big → bigger → the biggest" '
            'when they exist.\n'
            '- IPA: General American.\n'
            '- Conjunctions, pronouns, particles: category "other".'
        ),
    },
}

NATIVE = {
    'pt': {
        'name': 'Brazilian Portuguese',
        'approximation': (
            'Write it with Brazilian Portuguese spelling so a Brazilian '
            'reads it close to the real sound. Stressed syllable in '
            'UPPERCASE, hyphens between syllables only when it helps. '
            'Never use letter combinations that do not exist in Portuguese '
            '(no "th", "sh", "ee"); explain those sounds in phoneticTip '
            'instead. Examples: der Hund → "dér HUNT"; gehen → "GUÊ-en"; '
            'beautiful → "BIÚ-ti-ful".'
        ),
        'example': {
            'input': 'Hund',
            'output': {
                'category': 'masculineNoun', 'lemma': 'der Hund',
                'translation': 'o cachorro', 'ipa': 'deːɐ̯ hʊnt',
                'approximation': 'dér HUNT',
                'phoneticTip': 'O h é aspirado, como um suspiro. O d no '
                               'fim soa como t.',
                'plural': 'die Hunde', 'verbForms': None, 'degrees': None,
                'tagDetail': None, 'prepositionCase': None,
                'exampleSentence': 'Der Hund schläft im Garten.',
                'exampleTranslation': 'O cachorro dorme no jardim.',
            },
        },
    },
    'en': {
        'name': 'English',
        'approximation': (
            'Write it with English spelling so an English speaker reads it '
            'close to the real sound. Stressed syllable in UPPERCASE. '
            'Examples: der Hund → "dair HOONT"; gehen → "GAY-un".'
        ),
        'example': {
            'input': 'Hund',
            'output': {
                'category': 'masculineNoun', 'lemma': 'der Hund',
                'translation': 'the dog', 'ipa': 'deːɐ̯ hʊnt',
                'approximation': 'dair HOONT',
                'phoneticTip': 'The h is breathy, like a sigh. The d at '
                               'the end sounds like t.',
                'plural': 'die Hunde', 'verbForms': None, 'degrees': None,
                'tagDetail': None, 'prepositionCase': None,
                'exampleSentence': 'Der Hund schläft im Garten.',
                'exampleTranslation': 'The dog sleeps in the garden.',
            },
        },
    },
    'es': {
        'name': 'Spanish',
        'approximation': (
            'Write it with Spanish spelling so a Spanish speaker reads it '
            'close to the real sound. Stressed syllable in UPPERCASE. '
            'Examples: der Hund → "der JUNT"; gehen → "GUE-en".'
        ),
        'example': {
            'input': 'Hund',
            'output': {
                'category': 'masculineNoun', 'lemma': 'der Hund',
                'translation': 'el perro', 'ipa': 'deːɐ̯ hʊnt',
                'approximation': 'der JUNT',
                'phoneticTip': 'La h es aspirada, como un suspiro suave. '
                               'La d final suena como t.',
                'plural': 'die Hunde', 'verbForms': None, 'degrees': None,
                'tagDetail': None, 'prepositionCase': None,
                'exampleSentence': 'Der Hund schläft im Garten.',
                'exampleTranslation': 'El perro duerme en el jardín.',
            },
        },
    },
}

# Campos da resposta, na ordem da tela de cadastro.
FIELDS = [
    'category', 'lemma', 'translation', 'ipa', 'approximation',
    'phoneticTip', 'plural', 'verbForms', 'degrees', 'tagDetail',
    'prepositionCase', 'exampleSentence', 'exampleTranslation',
]
REQUIRED_TEXT = {
    'lemma', 'translation', 'ipa', 'approximation', 'phoneticTip',
    'exampleSentence', 'exampleTranslation',
}


def schema(study):
    """JSON Schema da resposta (todos os campos obrigatórios; os opcionais
    aceitam null), no formato aceito pelo modo estrito da OpenAI."""
    props = {}
    for f in FIELDS:
        if f == 'category':
            props[f] = {'type': 'string', 'enum': STUDY[study]['categories']}
        elif f in REQUIRED_TEXT:
            props[f] = {'type': 'string'}
        else:
            props[f] = {'type': ['string', 'null']}
    return {
        'type': 'object',
        'properties': props,
        'required': list(FIELDS),
        'additionalProperties': False,
    }


def system_prompt(study, native):
    import json
    s, n = STUDY[study], NATIVE[native]
    example = n['example']
    return f"""You fill in vocabulary flashcards for a {n['name']} speaker who is learning {s['name']}.
The user types one {s['name']} word or short expression. Return ONLY the JSON object described below, no extra text.

Fields:
- category: one of {', '.join(s['categories'])}.
- lemma: the dictionary form of the word, as it should be saved on the card.
- translation: short translation into {n['name']} (with article for nouns, e.g. "{example['output']['translation']}"); separate alternatives with ", ".
- ipa: IPA transcription of the lemma, WITHOUT brackets or slashes, with stress marks.
- approximation: {n['approximation']}
- phoneticTip: ONE short sentence in {n['name']} about the hardest sound for a {n['name']} speaker in this word.
- plural, verbForms, degrees, tagDetail, prepositionCase: only when they apply to this category, otherwise null.
- exampleSentence: one short, natural, everyday {s['name']} sentence (A1–B1) using the word.
- exampleTranslation: its translation into {n['name']}.

Rules for {s['name']}:
{s['rules']}

All explanations (translation, phoneticTip, tagDetail, prepositionCase, exampleTranslation) are written in {n['name']}.
If the input is not a real {s['name']} word, still return your best guess and say so in phoneticTip.

Example (the input was "{example['input']}"; the example is German, follow the same style for {s['name']}):
{json.dumps(example['output'], ensure_ascii=False)}"""


def user_prompt(word):
    return f'Word: {word}'
