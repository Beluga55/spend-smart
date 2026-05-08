import 'package:flutter/material.dart';

/// Formats AI-generated text for display.
/// Strips markdown, collapses whitespace.
class AIFormatter {
  static String format(String raw) {
    var text = raw;

    // Strip markdown bold
    text = text.replaceAllMapped(
      RegExp(r'\*\*\s*(.+?)\s*\*\*'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'\*\s*(.+?)\s*\*'),
      (m) => m.group(1)!,
    );
    text = text.replaceAll('__', '');

    // Collapse multiple spaces/tabs/newlines into single space
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{2,}'), '\n');

    return text.trim();
  }

  /// Converts markdown bold into bold TextSpans.
  static List<InlineSpan> toSpans(String raw, {required TextStyle baseStyle}) {
    final spans = <InlineSpan>[];
    final boldRe = RegExp(r'\*\*(.+?)\*\*');
    var lastEnd = 0;

    for (final match in boldRe.allMatches(raw)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: raw.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < raw.length) {
      spans.add(TextSpan(text: raw.substring(lastEnd), style: baseStyle));
    }

    return spans.isEmpty ? [TextSpan(text: raw, style: baseStyle)] : spans;
  }
}
