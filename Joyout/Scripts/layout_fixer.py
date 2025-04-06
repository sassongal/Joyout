#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

# דוגמה פשוטה להחלפה של תווים שהוקלדו בפריסה לא נכונה
def fix_layout(text):
    return text.replace("sus", "דוד").replace("hkud", "ניקוד")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("No text for layout fixing")
        sys.exit(1)

    input_text = sys.argv[1]
    fixed = fix_layout(input_text)
    print(fixed)
