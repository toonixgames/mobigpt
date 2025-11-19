import 'package:flutter/material.dart';

/// Utility class for detecting text language direction
class LanguageDetector {
  /// Hebrew Unicode range: U+0590 to U+05FF
  static const int _hebrewStart = 0x0590;
  static const int _hebrewEnd = 0x05FF;

  /// Detects if the text is primarily Hebrew or English
  /// Returns true if Hebrew (RTL), false if English (LTR)
  static bool isHebrew(String text) {
    if (text.isEmpty) return false;

    int hebrewCharCount = 0;
    int totalCharCount = 0;

    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      
      // Skip whitespace, punctuation, and common symbols
      if (_isWhitespaceOrPunctuation(codeUnit)) {
        continue;
      }

      totalCharCount++;
      
      // Check if character is in Hebrew Unicode range
      if (codeUnit >= _hebrewStart && codeUnit <= _hebrewEnd) {
        hebrewCharCount++;
      }
    }

    // If no meaningful characters found, default to LTR (English)
    if (totalCharCount == 0) return false;

    // If more than 30% of characters are Hebrew, consider it Hebrew
    // This handles mixed content and ensures Hebrew text is detected
    return (hebrewCharCount / totalCharCount) > 0.3;
  }

  /// Checks if a character is whitespace or punctuation
  static bool _isWhitespaceOrPunctuation(int codeUnit) {
    // Common whitespace and punctuation ranges
    return (codeUnit >= 0x0000 && codeUnit <= 0x0020) || // Control chars and space
           (codeUnit >= 0x2000 && codeUnit <= 0x206F) || // General punctuation
           (codeUnit >= 0x2E00 && codeUnit <= 0x2E7F) || // Supplemental punctuation
           (codeUnit >= 0x3000 && codeUnit <= 0x303F) || // CJK symbols and punctuation
           codeUnit == 0x00A0 || // Non-breaking space
           codeUnit == 0xFEFF;   // Zero-width no-break space
  }

  /// Gets the text direction based on language detection
  /// Returns TextDirection.rtl for Hebrew, TextDirection.ltr for English
  static TextDirection getTextDirection(String text) {
    return isHebrew(text) ? TextDirection.rtl : TextDirection.ltr;
  }
}

