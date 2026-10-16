#!/usr/bin/env python3
"""Writes a Swift check that every suggestion chip, in every language, is
understood by CoachTopic.detect (a chip that isn't gets a generic answer on
iPhones without Apple Intelligence)."""
import json, sys
catalog = json.load(open(sys.argv[1]))['strings']
print('import Foundation')
print('var bad = 0, total = 0')
for key in sorted(k for k in catalog if k.startswith('chat.suggest.') and k != 'chat.suggest.title'):
    for lang, loc in catalog[key]['localizations'].items():
        text = loc['stringUnit']['value'].replace('\\', '\\\\').replace('"', '\\"')
        print(f'total += 1; if CoachTopic.detect("{text}") == nil {{ bad += 1; print("  FALLO chip", "{key}", "{lang}") }}')
print('print(bad == 0 ? "TODO OK (\\(total) botones)" : "\\(bad) FALLOS")')
print('exit(bad == 0 ? 0 : 1)')
