import Foundation
import SwiftUI

class SmartTextAnalyzer: ObservableObject {
    static let shared = SmartTextAnalyzer()
    
    private init() {}
    
    // Enhanced character sets for better language detection
    private let hebrewChars = Set("אבגדהוזחטיכלמנסעפצקרשתםןץףך")
    private let englishChars = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private let nikudChars = Set("ְֱֲֳִֵֶַָֹֻּֽׁׂ")
    private let punctuationChars = Set(".,!?;:()[]{}\"'-")
    
    // Advanced pattern recognition for layout mistakes
    private let hebrewLayoutMistakePatterns: [(pattern: String, weight: Double)] = [
        // Common English patterns typed in Hebrew layout
        ("th", 0.8), ("sh", 0.7), ("ch", 0.6), ("st", 0.5), ("ng", 0.6),
        ("tion", 0.9), ("ing", 0.8), ("and", 0.7), ("the", 0.9), ("for", 0.6),
        ("you", 0.7), ("are", 0.6), ("not", 0.5), ("with", 0.6), ("this", 0.7),
        ("that", 0.7), ("have", 0.6), ("will", 0.6), ("from", 0.5), ("they", 0.6),
        ("what", 0.7), ("your", 0.6), ("when", 0.6), ("make", 0.5), ("like", 0.5)
    ]
    
    private let englishLayoutMistakePatterns: [(pattern: String, weight: Double)] = [
        // Common Hebrew patterns typed in English layout
        ("sh'", 0.8), ("ch'", 0.7), ("zch", 0.9), ("sha", 0.6), ("ar", 0.4),
        ("la", 0.4), ("ha", 0.5), ("ba", 0.5), ("ka", 0.5), ("ma", 0.5),
        ("na", 0.5), ("ta", 0.5), ("ra", 0.5), ("sa", 0.5), ("pa", 0.5),
        ("ga", 0.5), ("da", 0.5), ("za", 0.5), ("va", 0.5), ("fa", 0.5)
    ]
    
    // Comprehensive language vocabulary for better detection
    private let commonEnglishWords = Set([
        // Function words
        "the", "and", "you", "that", "was", "for", "are", "with", "his", "they",
        "have", "this", "will", "can", "had", "her", "what", "said", "each", "which",
        "she", "how", "their", "if", "up", "out", "many", "then", "them", "these",
        "so", "some", "would", "make", "like", "into", "him", "has", "two", "more",
        "very", "know", "just", "first", "get", "over", "think", "also", "back",
        "after", "use", "man", "good", "new", "here", "old", "see", "way", "who",
        // Common verbs
        "is", "be", "do", "go", "come", "take", "give", "work", "look", "feel",
        "try", "ask", "need", "seem", "turn", "start", "show", "hear", "play", "run",
        // Time and numbers
        "time", "year", "day", "week", "month", "hour", "minute", "today", "now",
        "one", "two", "three", "four", "five", "ten", "hundred", "thousand"
    ])
    
    private let commonHebrewWords = Set([
        // Function words
        "של", "את", "על", "לא", "זה", "או", "אם", "כל", "גם", "הוא", "היא", "אני",
        "רק", "עם", "יש", "היה", "כי", "אין", "מה", "כמו", "אבל", "שלא", "לכל",
        "היום", "הזה", "אחד", "פה", "שם", "יכול", "צריך", "יותר", "טוב", "נראה",
        "חושב", "רוצה", "דבר", "פעם", "שנים", "חיים", "עולם", "בית", "משפחה",
        // Prepositions and conjunctions
        "ב", "ל", "מ", "כ", "ש", "ו", "ה", "ממ", "בב", "לל", "כך", "ככה", "שש",
        // Common verbs
        "אמר", "בא", "הלך", "עשה", "נתן", "לקח", "ראה", "שמע", "ידע", "חשב",
        "אהב", "רצה", "יכל", "השב", "סיפר", "קרא", "כתב", "למד", "עבד", "שיחק",
        // Time and numbers
        "זמן", "שנה", "יום", "שבוע", "חודש", "שעה", "דקה", "עכשיו", "מחר", "אמש",
        "אחת", "שתיים", "שלוש", "ארבע", "חמש", "עשר", "מאה", "אלף", "מיליון"
    ])
    
    // Grammar and style patterns
    private let commonGrammarMistakes: [String: Double] = [
        // English grammar issues
        "should of": 0.9, "could of": 0.9, "would of": 0.9, "its": 0.6,
        "your": 0.5, "there": 0.5, "then": 0.4, "affect": 0.6, "alot": 0.8,
        // Hebrew grammar issues (simplified)
        "ה ה": 0.8, "ב ב": 0.8, "ל ל": 0.8, "מ מ": 0.8, "כ כ": 0.8
    ]
    
    // Text quality indicators
    private let textQualityPatterns: [(pattern: String, quality: TextQuality, weight: Double)] = [
        ("\\s{2,}", .needsCleaning, 0.7),     // Multiple spaces
        ("\\t", .needsCleaning, 0.8),          // Tabs
        ("\\n{3,}", .needsCleaning, 0.6),      // Excessive line breaks
        ("[!]{2,}", .needsCleaning, 0.5),     // Multiple exclamations
        ("[?]{2,}", .needsCleaning, 0.5),     // Multiple questions
        ("[.]{4,}", .needsCleaning, 0.7),     // Excessive periods
        ("\\b(\\w+)\\s+\\1\\b", .hasGrammarIssues, 0.8), // Repeated words
        ("([.!?])([A-Z])", .hasGrammarIssues, 0.4), // Missing space after punctuation
    ]
    
    func suggestBestOperation(for text: String) -> String {
        let analysis = analyzeText(text)
        
        // Enhanced priority system with confidence scoring
        let suggestions = getScoredSuggestions(analysis: analysis)
        let bestSuggestion = suggestions.max(by: { $0.score < $1.score })
        
        return bestSuggestion?.operation ?? "Layout Fixer"
    }
    
    func getMultipleSuggestions(for text: String, limit: Int = 3) -> [OperationSuggestion] {
        let analysis = analyzeText(text)
        let suggestions = getScoredSuggestions(analysis: analysis)
        
        return Array(suggestions.sorted(by: { $0.score > $1.score }).prefix(limit))
    }
    
    func getConfidence(for text: String, operation: String) -> Double {
        let analysis = analyzeText(text)
        
        switch operation {
        case "Layout Fixer":
            return analysis.layoutMistakeProbability
        case "Text Cleaner":
            return analysis.cleaningScore
        case "Hebrew Nikud":
            return analysis.nikudScore
        case "Language Corrector":
            return analysis.grammarScore
        case "Translator":
            return analysis.translationScore
        default:
            return 0.5
        }
    }
    
    func getDetailedAnalysis(for text: String) -> DetailedTextAnalysis {
        let baseAnalysis = analyzeText(text)
        
        return DetailedTextAnalysis(
            baseAnalysis: baseAnalysis,
            suggestions: getMultipleSuggestions(for: text, limit: 5),
            textQuality: assessTextQuality(text, analysis: baseAnalysis),
            languageDetails: getLanguageDetails(text, analysis: baseAnalysis),
            processingRecommendations: getProcessingRecommendations(baseAnalysis)
        )
    }
    
    private func getScoredSuggestions(analysis: TextAnalysis) -> [OperationSuggestion] {
        var suggestions: [OperationSuggestion] = []
        
        // Layout Fixer
        if analysis.layoutMistakeProbability > 0.3 {
            suggestions.append(OperationSuggestion(
                operation: "Layout Fixer",
                score: analysis.layoutMistakeProbability,
                reason: getLayoutFixerReason(analysis),
                confidence: analysis.layoutMistakeProbability
            ))
        }
        
        // Text Cleaner
        if analysis.cleaningScore > 0.4 {
            suggestions.append(OperationSuggestion(
                operation: "Text Cleaner",
                score: analysis.cleaningScore,
                reason: getTextCleanerReason(analysis),
                confidence: analysis.cleaningScore
            ))
        }
        
        // Hebrew Nikud
        if analysis.nikudScore > 0.5 {
            suggestions.append(OperationSuggestion(
                operation: "Hebrew Nikud",
                score: analysis.nikudScore,
                reason: "Hebrew text could benefit from vowel points (nikud)",
                confidence: analysis.nikudScore
            ))
        }
        
        // Language Corrector
        if analysis.grammarScore > 0.4 {
            suggestions.append(OperationSuggestion(
                operation: "Language Corrector",
                score: analysis.grammarScore,
                reason: getGrammarCorrectorReason(analysis),
                confidence: analysis.grammarScore
            ))
        }
        
        // Translator
        if analysis.translationScore > 0.5 {
            suggestions.append(OperationSuggestion(
                operation: "Translator",
                score: analysis.translationScore,
                reason: getTranslatorReason(analysis),
                confidence: analysis.translationScore
            ))
        }
        
        return suggestions
    }
    
    private func analyzeText(_ text: String) -> TextAnalysis {
        var analysis = TextAnalysis()
        
        // Basic text properties
        analysis.length = text.count
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.trimmed().isEmpty }
        analysis.wordCount = words.count
        analysis.sentenceCount = estimateSentenceCount(text)
        
        // Enhanced character analysis
        let characterStats = analyzeCharacters(text)
        analysis.hebrewRatio = characterStats.hebrewRatio
        analysis.englishRatio = characterStats.englishRatio
        analysis.punctuationRatio = characterStats.punctuationRatio
        analysis.whitespaceRatio = characterStats.whitespaceRatio
        
        // Advanced language detection
        let languageAnalysis = detectLanguageAdvanced(text, characterStats: characterStats)
        analysis.primaryLanguage = languageAnalysis.primary
        analysis.secondaryLanguage = languageAnalysis.secondary
        analysis.languageConfidence = languageAnalysis.confidence
        analysis.isHebrew = languageAnalysis.primary == .hebrew
        analysis.isEnglish = languageAnalysis.primary == .english
        analysis.isMixed = languageAnalysis.secondary != .unknown
        
        // Enhanced layout mistake detection
        analysis.layoutMistakeProbability = detectLayoutMistakeAdvanced(text, characterStats: characterStats, languageAnalysis: languageAnalysis)
        
        // Comprehensive quality assessment
        let qualityAnalysis = assessTextQualityAdvanced(text, words: words)
        analysis.cleaningScore = qualityAnalysis.cleaningScore
        analysis.grammarScore = qualityAnalysis.grammarScore
        analysis.stylisticIssues = qualityAnalysis.stylisticIssues
        
        // Specialized Hebrew analysis
        if analysis.isHebrew || analysis.isMixed {
            analysis.nikudScore = assessNikudNeed(text, words: words)
            analysis.hasNikud = containsNikud(text)
        }
        
        // Translation assessment
        analysis.translationScore = assessTranslationNeed(text, languageAnalysis: languageAnalysis)
        
        // Advanced pattern recognition
        analysis.suspiciousPatterns = detectSuspiciousPatterns(text)
        analysis.textComplexity = calculateTextComplexity(text, words: words)
        analysis.readabilityScore = calculateReadabilityScore(text, words: words, sentences: analysis.sentenceCount)
        
        return analysis
    }
    
    private func analyzeCharacters(_ text: String) -> CharacterStatistics {
        var stats = CharacterStatistics()
        
        let chars = Array(text)
        stats.totalChars = chars.count
        
        for char in chars {
            if hebrewChars.contains(char) {
                stats.hebrewCount += 1
            } else if englishChars.contains(char) {
                stats.englishCount += 1
            } else if nikudChars.contains(char) {
                stats.nikudCount += 1
            } else if punctuationChars.contains(char) {
                stats.punctuationCount += 1
            } else if char.isWhitespace {
                stats.whitespaceCount += 1
            } else if char.isNumber {
                stats.numberCount += 1
            } else {
                stats.otherCount += 1
            }
        }
        
        let letterCount = stats.hebrewCount + stats.englishCount
        if letterCount > 0 {
            stats.hebrewRatio = Double(stats.hebrewCount) / Double(letterCount)
            stats.englishRatio = Double(stats.englishCount) / Double(letterCount)
        }
        
        if stats.totalChars > 0 {
            stats.punctuationRatio = Double(stats.punctuationCount) / Double(stats.totalChars)
            stats.whitespaceRatio = Double(stats.whitespaceCount) / Double(stats.totalChars)
            stats.numberRatio = Double(stats.numberCount) / Double(stats.totalChars)
        }
        
        return stats
    }
    
    private func detectLanguageAdvanced(_ text: String, characterStats: CharacterStatistics) -> LanguageAnalysis {
        var analysis = LanguageAnalysis()
        
        // Character-based detection
        let charScore = characterStats.hebrewRatio - characterStats.englishRatio
        
        // Word-based detection
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        var hebrewWordScore = 0.0
        var englishWordScore = 0.0
        
        for word in words {
            if commonHebrewWords.contains(word) {
                hebrewWordScore += 1.0
            }
            if commonEnglishWords.contains(word) {
                englishWordScore += 1.0
            }
        }
        
        let totalWords = Double(words.count)
        if totalWords > 0 {
            hebrewWordScore /= totalWords
            englishWordScore /= totalWords
        }
        
        // Combined scoring
        let hebrewScore = (charScore * 0.6) + (hebrewWordScore * 0.4)
        let englishScore = (-charScore * 0.6) + (englishWordScore * 0.4)
        
        // Determine primary language
        if hebrewScore > 0.3 && hebrewScore > englishScore {
            analysis.primary = .hebrew
            analysis.confidence = min(hebrewScore, 0.95)
        } else if englishScore > 0.3 && englishScore > hebrewScore {
            analysis.primary = .english
            analysis.confidence = min(englishScore, 0.95)
        } else {
            analysis.primary = .mixed
            analysis.confidence = 0.5
        }
        
        // Determine secondary language
        if analysis.primary != .mixed {
            let secondaryScore = analysis.primary == .hebrew ? englishScore : hebrewScore
            if secondaryScore > 0.2 {
                analysis.secondary = analysis.primary == .hebrew ? .english : .hebrew
            }
        }
        
        return analysis
    }
    
    private func detectLayoutMistakeAdvanced(_ text: String, characterStats: CharacterStatistics, languageAnalysis: LanguageAnalysis) -> Double {
        var mistakeScore = 0.0
        let lowercased = text.lowercased()
        
        // Pattern-based detection with weighted scoring
        if characterStats.englishRatio > 0.8 {
            // Likely English characters, check for Hebrew patterns
            for (pattern, weight) in hebrewLayoutMistakePatterns {
                let occurrences = lowercased.components(separatedBy: pattern).count - 1
                mistakeScore += Double(occurrences) * weight * 0.1
            }
        }
        
        if characterStats.hebrewRatio > 0.8 {
            // Likely Hebrew characters, check for English patterns
            for (pattern, weight) in englishLayoutMistakePatterns {
                let occurrences = text.components(separatedBy: pattern).count - 1
                mistakeScore += Double(occurrences) * weight * 0.1
            }
        }
        
        // Enhanced alternating pattern detection
        let alternatingScore = detectAlternatingPatterns(text)
        mistakeScore += alternatingScore * 0.5
        
        // Keyboard distance analysis
        let keyboardDistanceScore = analyzeKeyboardDistance(text)
        mistakeScore += keyboardDistanceScore * 0.3
        
        // Language mismatch penalty
        if languageAnalysis.confidence > 0.8 {
            let mismatchScore = calculateLanguageMismatch(text, expectedLanguage: languageAnalysis.primary)
            mistakeScore += mismatchScore * 0.4
        }
        
        return min(mistakeScore, 1.0)
    }
    
    private func assessTextQualityAdvanced(_ text: String, words: [String]) -> QualityAnalysis {
        var analysis = QualityAnalysis()
        
        // Pattern-based quality assessment
        for (pattern, quality, weight) in textQualityPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.numberOfMatches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? 0
            
            if matches > 0 {
                switch quality {
                case .needsCleaning:
                    analysis.cleaningScore += Double(matches) * weight * 0.1
                case .hasGrammarIssues:
                    analysis.grammarScore += Double(matches) * weight * 0.1
                case .hasStylisticIssues:
                    analysis.stylisticIssues += Double(matches) * weight * 0.1
                }
            }
        }
        
        // Grammar mistake detection
        for (mistake, weight) in commonGrammarMistakes {
            let occurrences = text.lowercased().components(separatedBy: mistake.lowercased()).count - 1
            if occurrences > 0 {
                analysis.grammarScore += Double(occurrences) * weight * 0.15
            }
        }
        
        // Word-level analysis
        let uniqueWords = Set(words.map { $0.lowercased() })
        let repetitionRatio = 1.0 - (Double(uniqueWords.count) / Double(max(words.count, 1)))
        if repetitionRatio > 0.3 {
            analysis.grammarScore += repetitionRatio * 0.3
        }
        
        // Sentence structure analysis
        let avgWordsPerSentence = Double(words.count) / Double(max(estimateSentenceCount(text), 1))
        if avgWordsPerSentence < 3 || avgWordsPerSentence > 40 {
            analysis.stylisticIssues += 0.2
        }
        
        // Normalize scores
        analysis.cleaningScore = min(analysis.cleaningScore, 1.0)
        analysis.grammarScore = min(analysis.grammarScore, 1.0)
        analysis.stylisticIssues = min(analysis.stylisticIssues, 1.0)
        
        return analysis
    }
    
    // Additional helper methods
    private func detectAlternatingPatterns(_ text: String) -> Double {
        let chars = Array(text.lowercased())
        guard chars.count > 1 else { return 0.0 }
        
        var alternatingCount = 0
        var consecutiveAlternations = 0
        var maxConsecutiveAlternations = 0
        
        for i in 1..<chars.count {
            let prevIsHebrew = hebrewChars.contains(chars[i-1])
            let currIsHebrew = hebrewChars.contains(chars[i])
            let prevIsEnglish = englishChars.contains(chars[i-1])
            let currIsEnglish = englishChars.contains(chars[i])
            
            if (prevIsHebrew && currIsEnglish) || (prevIsEnglish && currIsHebrew) {
                alternatingCount += 1
                consecutiveAlternations += 1
                maxConsecutiveAlternations = max(maxConsecutiveAlternations, consecutiveAlternations)
            } else {
                consecutiveAlternations = 0
            }
        }
        
        let alternatingRatio = Double(alternatingCount) / Double(chars.count - 1)
        let consecutiveBonus = Double(maxConsecutiveAlternations) * 0.1
        
        return min(alternatingRatio + consecutiveBonus, 1.0)
    }
    
    private func analyzeKeyboardDistance(_ text: String) -> Double {
        // Simplified keyboard distance analysis
        // In a real implementation, this would calculate actual key distances
        let chars = Array(text.lowercased())
        var suspiciousSequences = 0
        
        for i in 1..<chars.count {
            let prev = chars[i-1]
            let curr = chars[i]
            
            // Check for unlikely character combinations that suggest layout mistakes
            if (hebrewChars.contains(prev) && englishChars.contains(curr)) ||
               (englishChars.contains(prev) && hebrewChars.contains(curr)) {
                suspiciousSequences += 1
            }
        }
        
        return min(Double(suspiciousSequences) / Double(max(chars.count - 1, 1)), 1.0)
    }
    
    private func calculateLanguageMismatch(_ text: String, expectedLanguage: DetectedLanguage) -> Double {
        // Calculate how much the text deviates from expected language patterns
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        var mismatchScore = 0.0
        
        for word in words {
            switch expectedLanguage {
            case .hebrew:
                if word.allSatisfy({ englishChars.contains($0) }) {
                    mismatchScore += 1.0
                }
            case .english:
                if word.allSatisfy({ hebrewChars.contains($0) }) {
                    mismatchScore += 1.0
                }
            default:
                break
            }
        }
        
        return min(mismatchScore / Double(max(words.count, 1)), 1.0)
    }
    
    private func assessNikudNeed(_ text: String, words: [String]) -> Double {
        guard containsHebrew(text) else { return 0.0 }
        
        let hasExistingNikud = containsNikud(text)
        if hasExistingNikud { return 0.2 }
        
        var nikudScore = 0.5 // Base score for Hebrew text without nikud
        
        // Longer texts benefit more from nikud
        if text.count > 50 {
            nikudScore += 0.2
        }
        
        // Texts with complex words benefit more
        let avgWordLength = words.isEmpty ? 0 : Double(text.count) / Double(words.count)
        if avgWordLength > 5 {
            nikudScore += 0.2
        }
        
        return min(nikudScore, 1.0)
    }
    
    private func assessTranslationNeed(_ text: String, languageAnalysis: LanguageAnalysis) -> Double {
        guard languageAnalysis.confidence > 0.7 else { return 0.3 }
        
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.trimmingCharacters(in: .punctuationCharacters).isEmpty }.count
        
        if wordCount < 3 { return 0.2 }
        if wordCount > 20 { return 0.8 }
        
        return 0.6
    }
    
    private func detectSuspiciousPatterns(_ text: String) -> [String] {
        var patterns: [String] = []
        
        if text.contains("  ") {
            patterns.append("Multiple consecutive spaces")
        }
        
        if text.contains("\t") {
            patterns.append("Tab characters")
        }
        
        if text.range(of: "\\n{3,}", options: .regularExpression) != nil {
            patterns.append("Excessive line breaks")
        }
        
        if detectAlternatingPatterns(text) > 0.3 {
            patterns.append("Alternating language characters")
        }
        
        return patterns
    }
    
    private func calculateTextComplexity(_ text: String, words: [String]) -> Double {
        let avgWordLength = words.isEmpty ? 0 : Double(text.count) / Double(words.count)
        let uniqueWords = Set(words.map { $0.lowercased() })
        let vocabularyRichness = words.isEmpty ? 0 : Double(uniqueWords.count) / Double(words.count)
        
        return (avgWordLength / 10.0 + vocabularyRichness) / 2.0
    }
    
    private func calculateReadabilityScore(_ text: String, words: [String], sentences: Int) -> Double {
        guard !words.isEmpty && sentences > 0 else { return 0.0 }
        
        let avgWordsPerSentence = Double(words.count) / Double(sentences)
        let avgSyllablesPerWord = estimateAverageSyllables(words)
        
        // Simplified readability calculation
        let readabilityScore = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllablesPerWord)
        
        return max(0, min(100, readabilityScore)) / 100.0
    }
    
    // Helper functions for quality assessment
    private func containsHebrew(_ text: String) -> Bool {
        return text.contains { hebrewChars.contains($0) }
    }
    
    private func containsNikud(_ text: String) -> Bool {
        return text.contains { nikudChars.contains($0) }
    }
    
    private func estimateSentenceCount(_ text: String) -> Int {
        let sentenceEnders = CharacterSet(charactersIn: ".!?")
        return max(1, text.components(separatedBy: sentenceEnders).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count)
    }
    
    private func estimateAverageSyllables(_ words: [String]) -> Double {
        // Simplified syllable estimation
        let totalSyllables = words.reduce(0) { result, word in
            let vowelCount = word.filter { "aeiouAEIOU".contains($0) }.count
            return result + max(1, vowelCount)
        }
        
        return words.isEmpty ? 1.0 : Double(totalSyllables) / Double(words.count)
    }
    
    // Reason generators for suggestions
    private func getLayoutFixerReason(_ analysis: TextAnalysis) -> String {
        if analysis.layoutMistakeProbability > 0.8 {
            return "High probability of keyboard layout mistake detected"
        } else if analysis.layoutMistakeProbability > 0.6 {
            return "Possible keyboard layout mistake - mixed character patterns found"
        } else {
            return "Some inconsistent character patterns detected"
        }
    }
    
    private func getTextCleanerReason(_ analysis: TextAnalysis) -> String {
        if analysis.cleaningScore > 0.8 {
            return "Text contains multiple formatting issues requiring cleanup"
        } else if analysis.cleaningScore > 0.6 {
            return "Some whitespace and punctuation issues detected"
        } else {
            return "Minor formatting improvements available"
        }
    }
    
    private func getGrammarCorrectorReason(_ analysis: TextAnalysis) -> String {
        if analysis.grammarScore > 0.8 {
            return "Multiple grammar and spelling issues detected"
        } else if analysis.grammarScore > 0.6 {
            return "Some grammar and language issues found"
        } else {
            return "Minor language improvements available"
        }
    }
    
    private func getTranslatorReason(_ analysis: TextAnalysis) -> String {
        switch analysis.primaryLanguage {
        case .hebrew:
            return "Hebrew text - translation to English available"
        case .english:
            return "English text - translation to Hebrew available"
        case .mixed:
            return "Mixed language text - partial translation available"
        case .unknown:
            return "Translation may help clarify language issues"
        }
    }
    
    private func assessTextQuality(_ text: String, analysis: TextAnalysis) -> TextQualityAssessment {
        let overallScore = (1.0 - analysis.cleaningScore) * (1.0 - analysis.grammarScore) * (1.0 - analysis.stylisticIssues)
        
        let quality: TextQualityLevel
        if overallScore > 0.8 {
            quality = .excellent
        } else if overallScore > 0.6 {
            quality = .good
        } else if overallScore > 0.4 {
            quality = .fair
        } else {
            quality = .poor
        }
        
        return TextQualityAssessment(
            level: quality,
            score: overallScore,
            issues: analysis.suspiciousPatterns,
            recommendations: getQualityRecommendations(analysis)
        )
    }
    
    private func getLanguageDetails(_ text: String, analysis: TextAnalysis) -> LanguageDetails {
        return LanguageDetails(
            primary: analysis.primaryLanguage,
            secondary: analysis.secondaryLanguage,
            confidence: analysis.languageConfidence,
            hasNikud: analysis.hasNikud,
            complexity: analysis.textComplexity,
            readability: analysis.readabilityScore
        )
    }
    
    private func getProcessingRecommendations(_ analysis: TextAnalysis) -> [String] {
        var recommendations: [String] = []
        
        if analysis.layoutMistakeProbability > 0.5 {
            recommendations.append("Use Layout Fixer to correct keyboard layout mistakes")
        }
        
        if analysis.cleaningScore > 0.5 {
            recommendations.append("Use Text Cleaner to improve formatting")
        }
        
        if analysis.grammarScore > 0.5 {
            recommendations.append("Use Language Corrector to fix grammar issues")
        }
        
        if analysis.nikudScore > 0.7 {
            recommendations.append("Add Hebrew Nikud for better readability")
        }
        
        if analysis.translationScore > 0.6 {
            recommendations.append("Consider translation for broader accessibility")
        }
        
        return recommendations
    }
    
    private func getQualityRecommendations(_ analysis: TextAnalysis) -> [String] {
        var recommendations: [String] = []
        
        if analysis.cleaningScore > 0.5 {
            recommendations.append("Clean up whitespace and formatting")
        }
        
        if analysis.grammarScore > 0.5 {
            recommendations.append("Review grammar and spelling")
        }
        
        if analysis.stylisticIssues > 0.5 {
            recommendations.append("Improve sentence structure and flow")
        }
        
        if analysis.textComplexity < 0.3 {
            recommendations.append("Consider adding more varied vocabulary")
        }
        
        return recommendations
    }
    
    // MARK: - Data Structures
    
    struct TextAnalysis {
        var length: Int = 0
        var wordCount: Int = 0
        var sentenceCount: Int = 0
        var hebrewRatio: Double = 0.0
        var englishRatio: Double = 0.0
        var punctuationRatio: Double = 0.0
        var whitespaceRatio: Double = 0.0
        var primaryLanguage: DetectedLanguage = .unknown
        var secondaryLanguage: DetectedLanguage = .unknown
        var languageConfidence: Double = 0.0
        var isHebrew: Bool = false
        var isEnglish: Bool = false
        var isMixed: Bool = false
        var layoutMistakeProbability: Double = 0.0
        var cleaningScore: Double = 0.0
        var grammarScore: Double = 0.0
        var nikudScore: Double = 0.0
        var translationScore: Double = 0.0
        var hasNikud: Bool = false
        var stylisticIssues: Double = 0.0
        var suspiciousPatterns: [String] = []
        var textComplexity: Double = 0.0
        var readabilityScore: Double = 0.0
    }
    
    struct CharacterStatistics {
        var totalChars: Int = 0
        var hebrewCount: Int = 0
        var englishCount: Int = 0
        var nikudCount: Int = 0
        var punctuationCount: Int = 0
        var whitespaceCount: Int = 0
        var numberCount: Int = 0
        var otherCount: Int = 0
        var hebrewRatio: Double = 0.0
        var englishRatio: Double = 0.0
        var punctuationRatio: Double = 0.0
        var whitespaceRatio: Double = 0.0
        var numberRatio: Double = 0.0
    }
    
    struct LanguageAnalysis {
        var primary: DetectedLanguage = .unknown
        var secondary: DetectedLanguage = .unknown
        var confidence: Double = 0.0
    }
    
    struct QualityAnalysis {
        var cleaningScore: Double = 0.0
        var grammarScore: Double = 0.0
        var stylisticIssues: Double = 0.0
    }
    
    struct OperationSuggestion {
        let operation: String
        let score: Double
        let reason: String
        let confidence: Double
    }
    
    struct DetailedTextAnalysis {
        let baseAnalysis: TextAnalysis
        let suggestions: [OperationSuggestion]
        let textQuality: TextQualityAssessment
        let languageDetails: LanguageDetails
        let processingRecommendations: [String]
    }
    
    struct TextQualityAssessment {
        let level: TextQualityLevel
        let score: Double
        let issues: [String]
        let recommendations: [String]
    }
    
    struct LanguageDetails {
        let primary: DetectedLanguage
        let secondary: DetectedLanguage
        let confidence: Double
        let hasNikud: Bool
        let complexity: Double
        let readability: Double
    }
    
    enum DetectedLanguage {
        case hebrew, english, mixed, unknown
    }
    
    enum TextQuality {
        case needsCleaning, hasGrammarIssues, hasStylisticIssues
    }
    
    enum TextQualityLevel {
        case excellent, good, fair, poor
    }
}

// String extension for convenience
extension String {
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
