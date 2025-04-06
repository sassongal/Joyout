#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

def add_nikud(text):
    nikud_map = {
        "שלום": "שָׁלוֹם",
        "אהבה": "אַהֲבָה",
        "מים": "מַיִם"
    }
    return nikud_map.get(text.strip(), text + " (עם ניקוד דמיוני)")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("אין טקסט להוספת ניקוד")
        sys.exit(1)

    input_text = sys.argv[1]
    result = add_nikud(input_text)
    print(result)
