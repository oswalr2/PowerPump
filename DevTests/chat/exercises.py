#!/usr/bin/env python3
"""Writes a Swift check that the question the exercise screen sends to
Spartan ("How do I do <name>?") is understood as a how-to question for every
exercise in the library, in every language."""
import json, re, sys
root = sys.argv[1]
db = open(root + '/Core/Services/ExerciseDatabase.swift').read()
names = re.findall(r'id: "[a-z_]+",\s*name: "([^"]+)"', db)
strings = open(root + '/Core/Services/ExerciseStrings.swift').read()
catalog = json.load(open(root + '/Localizable.xcstrings'))['strings']
question = catalog['exercise.spartan.question']['localizations']
def local(name, lang):
    if lang == 'en': return name
    block = strings[strings.index('"%s": [' % lang):]
    m = re.search(r'"%s":\s*"((?:[^"\\]|\\.)*)"' % re.escape(name), block)
    return m.group(1) if m else name
print('import Foundation')
print('var bad = 0, total = 0')
for lang in ['en', 'es', 'fr', 'it', 'pt-BR']:
    fmt = question[lang]['stringUnit']['value']
    for n in names:
        q = fmt.replace('%@', local(n, lang)).replace('\\', '\\\\').replace('"', '\\"')
        print(f'total += 1; if CoachTopic.detect("{q}") != .exerciseHowTo {{ bad += 1; print("  FALLO", "{lang}", "{q}", CoachTopic.detect("{q}")?.rawValue ?? "nada") }}')
print('print(bad == 0 ? "TODO OK (\\(total) preguntas)" : "\\(bad) FALLOS")')
print('exit(bad == 0 ? 0 : 1)')
