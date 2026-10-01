#!/usr/bin/env python3
"""Adds localized strings to app_en/gu/hi.arb in one step so the three
languages never drift. Input: a Python file defining STRINGS = {
  key: (en, gu, hi, description, placeholders_or_None) }.
Usage: python3 tool/add_strings.py strings_batch.py
"""
import json, sys, runpy, collections

batch = runpy.run_path(sys.argv[1])["STRINGS"]
files = {"en": "lib/l10n/app_en.arb", "gu": "lib/l10n/app_gu.arb", "hi": "lib/l10n/app_hi.arb"}
for lang, path in files.items():
    data = json.load(open(path), object_pairs_hook=collections.OrderedDict)
    for key, (en, gu, hi, desc, placeholders) in batch.items():
        if key in data:
            raise SystemExit(f"duplicate key {key} in {path}")
        data[key] = {"en": en, "gu": gu, "hi": hi}[lang]
        if lang == "en":
            meta = {"description": desc}
            if placeholders:
                meta["placeholders"] = placeholders
            data["@" + key] = meta
    with open(path, "w") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
print(f"added {len(batch)} strings")
