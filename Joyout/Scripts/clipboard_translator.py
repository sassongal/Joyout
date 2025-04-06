#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

def translate(text):
    dictionary = {
        "שלום": "akuo",
        "אהבה": "amour",
        "מים": "aqua",
        "אני": "mi",
        "אתה": "tu"
    }
    return dictionary.get(text.strip(), f"[no translation for '{text}']")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("No input text provided.")
        sys.exit(1)

    input_text = sys.argv[1]
    translated = translate(input_text)
    print(translated)
