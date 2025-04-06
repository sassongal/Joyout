#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Nothing to send to Notepad")
        sys.exit(1)

    text = sys.argv[1]

    try:
        with open("/tmp/joyout_text.txt", "w", encoding="utf-8") as f:
            f.write(text)
        print(text)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
