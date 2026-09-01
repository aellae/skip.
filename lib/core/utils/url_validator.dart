/// Parses [value] as an http(s) URL, returning `null` if it's blank or
/// isn't a well-formed http(s) link. SKIP never fetches or previews the
/// link's content — this only guards what gets stored and later handed to
/// the OS to open, so the accepted shape is a plain browsable URL.
Uri? parseHttpUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasAuthority) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}
