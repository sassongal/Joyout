#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

def correct_text(text):
    # כאן אפשר להרחיב ל־AI אמיתי
    return text.replace("סבא שלי הוא אבא שלי", "סבא שלי הוא סבא שלי")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("אין טקסט לתיקון")
        sys.exit(1)

    input_text = sys.argv[1]
    corrected = correct_text(input_text)
    print(corrected)
