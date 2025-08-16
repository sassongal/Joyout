import Foundation

class PythonBridge {
    
    static let shared = PythonBridge()
    private init() {}
    
    private func findPythonExecutable() -> String {
        // Common Python3 locations
        let pythonPaths = [
            "/usr/bin/python3",
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.10/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.9/bin/python3"
        ]
        
        for path in pythonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Fallback to system python3
        return "/usr/bin/python3"
    }
    
    func executeTextProcessing(operation: String, text: String, apiKey: String = "") -> String? {
        let python3Path = findPythonExecutable()
        
        // Create a temporary Python script for text processing
        let script = createTextProcessingScript(operation: operation, text: text, apiKey: apiKey)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("joyaas_temp.py")
        
        do {
            try script.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: python3Path)
            process.arguments = [tempURL.path]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            
            return output
            
        } catch {
            print("Python bridge error: \(error)")
            return nil
        }
    }
    
    private func createTextProcessingScript(operation: String, text: String, apiKey: String) -> String {
        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedApiKey = apiKey.replacingOccurrences(of: "\"", with: "\\\"")
        
        return """
        #!/usr/bin/env python3
        import re
        import json
        import urllib.request
        import urllib.parse
        import urllib.error
        import sys
        
        def fix_layout(text):
            \"\"\"Fix text typed in wrong keyboard layout\"\"\"
            if not text.strip():
                return text
            
            hebrew_to_english = {
                'א': 't', 'ב': 'c', 'ג': 'd', 'ד': 's', 'ה': 'b', 'ו': 'o', 'ז': 'z', 'ח': 'g',
                'ט': 'y', 'י': 'h', 'כ': 'f', 'ל': 'k', 'מ': 'n', 'נ': 'j', 'ס': 'x', 'ע': 'u',
                'פ': 'p', 'צ': 'm', 'ק': 'e', 'ר': 'r', 'ש': 'a', 'ת': ',', 'ן': 'l', 'ם': 'o',
                'ף': ';', 'ץ': '.', 'ך': 'i'
            }
            
            english_to_hebrew = {v: k for k, v in hebrew_to_english.items()}
            
            # Try both directions
            if any(c in english_to_hebrew for c in text.lower()):
                return ''.join(english_to_hebrew.get(c.lower(), c) for c in text)
            elif any(c in hebrew_to_english for c in text):
                return ''.join(hebrew_to_english.get(c, c) for c in text)
            
            return text
        
        def clean_text(text):
            \"\"\"Remove formatting artifacts\"\"\"
            cleaned = re.sub(r'\\\\s+', ' ', text)
            cleaned = re.sub(r'[_]{2,}', '', cleaned)
            cleaned = re.sub(r'[.]{3,}', '...', cleaned)
            cleaned = re.sub(r'[!]{2,}', '!', cleaned)
            cleaned = re.sub(r'[?]{2,}', '?', cleaned)
            cleaned = re.sub(r'\\\\n\\\\s*\\\\n\\\\s*\\\\n', '\\\\n\\\\n', cleaned)
            return cleaned.strip()
        
        def call_google_ai(prompt, api_key):
            \"\"\"Call Google AI API for text processing\"\"\"
            if not api_key:
                return None
            
            try:
                url = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}'
                
                data = {
                    'contents': [{'parts': [{'text': prompt}]}],
                    'generationConfig': {
                        'temperature': 0.1,
                        'maxOutputTokens': 1000
                    }
                }
                
                req = urllib.request.Request(url)
                req.add_header('Content-Type', 'application/json')
                req_data = json.dumps(data).encode('utf-8')
                
                with urllib.request.urlopen(req, req_data, timeout=30) as response:
                    result = json.loads(response.read().decode('utf-8'))
                    
                if 'candidates' in result and len(result['candidates']) > 0:
                    candidate = result['candidates'][0]
                    if 'content' in candidate and 'parts' in candidate['content']:
                        parts = candidate['content']['parts']
                        if len(parts) > 0 and 'text' in parts[0]:
                            return parts[0]['text'].strip()
                            
            except Exception as e:
                return f"Error calling AI: {str(e)}"
            
            return None
        
        def detect_language(text):
            \"\"\"Detect if text is primarily Hebrew or English\"\"\"
            hebrew_chars = sum(1 for c in text if '\\u0590' <= c <= '\\u05FF')
            english_chars = sum(1 for c in text if c.isalpha() and c.isascii())
            return "hebrew" if hebrew_chars > english_chars else "english"
        
        def add_hebrew_nikud(text, api_key):
            \"\"\"Add Hebrew nikud using AI\"\"\"
            if not api_key:
                return "⚠️ Google AI API key required for Hebrew Nikud"
            
            prompt = f'''Add Hebrew nikud (vowelization) to the following Hebrew text. Only add nikud where needed for proper pronunciation and understanding. Return only the text with nikud added:
        
        {text}'''
            
            result = call_google_ai(prompt, api_key)
            return result if result else text
        
        def correct_language(text, api_key):
            \"\"\"Correct spelling and grammar\"\"\"
            if not api_key:
                return "⚠️ Google AI API key required for Language Correction"
            
            language = detect_language(text)
            lang_name = "Hebrew" if language == "hebrew" else "English"
            
            prompt = f'''Fix any spelling and grammar errors in the following {lang_name} text. Preserve the original meaning and style. Return only the corrected text:
        
        {text}'''
            
            result = call_google_ai(prompt, api_key)
            return result if result else text
        
        def translate_text(text, api_key):
            \"\"\"Translate between Hebrew and English\"\"\"
            if not api_key:
                return "⚠️ Google AI API key required for Translation"
            
            language = detect_language(text)
            target_lang = "English" if language == "hebrew" else "Hebrew"
            
            prompt = f'''Translate the following text to {target_lang}. Preserve meaning and tone:
        
        {text}'''
            
            result = call_google_ai(prompt, api_key)
            return result if result else text
        
        # Main processing logic
        operation = "\(operation)"
        text = "\(escapedText)"
        api_key = "\(escapedApiKey)"
        
        if operation == "layout_fixer":
            result = fix_layout(text)
        elif operation == "text_cleaner":
            result = clean_text(text)
        elif operation == "hebrew_nikud":
            result = add_hebrew_nikud(text, api_key)
        elif operation == "language_corrector":
            result = correct_language(text, api_key)
        elif operation == "translator":
            result = translate_text(text, api_key)
        else:
            result = "Unknown operation"
        
        print(result)
        """
    }
}
