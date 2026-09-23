/// Picks one motto per calendar day, so the Home screen and the native
/// widgets show the same line all day and it changes at local midnight.
///
/// Must stay in sync with `mottoOfTheDay` in ios/SkipWidget/SkipWidget.swift:
/// both index by whole days since 1970-01-01 for the local calendar date.
String mottoOfTheDay(List<String> mottos, DateTime now) {
  final day =
      DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  return mottos[day % mottos.length];
}

const _nbsp = ' ';

/// Swaps in non-breaking spaces where a line break would read wrong, so a
/// motto wraps cleanly in every language, in the app and in the native
/// widgets alike (they receive the already-typeset string):
/// - French high punctuation (`?`, `!`, `:`, `;`, `»`) never starts a line,
///   and `«` never ends one.
/// - Symbols that bind two words (`≠`, `=`) stay with both; a dash (`–`,
///   `—`) stays with the word before it, so a line may end on it but never
///   start with it.
/// - The last two words stay together, so no word is left alone on the final
///   line (unless that's the whole motto, which wraps fine as is).
String typesetMotto(String text) {
  var result = text
      .replaceAllMapped(RegExp(r' ([?!:;»])'), (m) => '$_nbsp${m[1]}')
      .replaceAll('« ', '«$_nbsp')
      .replaceAllMapped(RegExp(r' ([≠=]) '), (m) => '$_nbsp${m[1]}$_nbsp')
      .replaceAllMapped(RegExp(r' ([–—]) '), (m) => '$_nbsp${m[1]} ');
  final lastSpace = result.lastIndexOf(' ');
  final wordCount = result.split(RegExp('[ $_nbsp]')).length;
  if (lastSpace > 0 && wordCount > 2) {
    result =
        '${result.substring(0, lastSpace)}$_nbsp${result.substring(lastSpace + 1)}';
  }
  return result;
}
