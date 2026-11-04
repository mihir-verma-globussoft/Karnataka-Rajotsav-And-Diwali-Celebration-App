/// Collapses runs of whitespace, trims, and cuts to [max] characters, counted
/// as Unicode code points so emoji and Indian-script letters are never split
/// in half.
String cleanText(String input, int max) {
  final collapsed = input.replaceAll(RegExp(r'\s+'), ' ').trim();
  final runes = collapsed.runes.toList();
  if (runes.length <= max) return collapsed;
  return String.fromCharCodes(runes.take(max)).trimRight();
}
