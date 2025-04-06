#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

def remove_underlines(text):
    return text.replace("_", "")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("No text to clean")
        sys.exit(1)

    input_text = sys.argv[1]
    cleaned = remove_underlines(input_text)
    print(cleaned)
