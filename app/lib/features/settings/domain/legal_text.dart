/// Minimal, dependency-free reader for the bundled legal Markdown
/// (docs/legal/*.md): headings, notes, bullets, paragraphs and simple tables.
/// Anything richer is shown as plain text — never dropped.
sealed class LegalBlock {
  const LegalBlock(this.text);

  final String text;
}

final class LegalHeading extends LegalBlock {
  const LegalHeading(super.text, {required this.level});

  final int level;
}

final class LegalNote extends LegalBlock {
  const LegalNote(super.text);
}

final class LegalBullet extends LegalBlock {
  const LegalBullet(super.text);
}

final class LegalParagraph extends LegalBlock {
  const LegalParagraph(super.text);
}

final _tableSeparator = RegExp(r'^\|?\s*:?-{3,}');
final _emphasis = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');

String _plain(String s) => s.replaceAllMapped(_emphasis, (m) => m.group(1) ?? m.group(2)!).trim();

List<LegalBlock> parseLegalMarkdown(String source) {
  final blocks = <LegalBlock>[];
  final paragraph = <String>[];
  final note = <String>[];

  void flush() {
    if (paragraph.isNotEmpty) blocks.add(LegalParagraph(_plain(paragraph.join(' '))));
    if (note.isNotEmpty) blocks.add(LegalNote(_plain(note.join(' '))));
    paragraph.clear();
    note.clear();
  }

  for (final raw in source.split('\n')) {
    final line = raw.trimRight();
    final trimmed = line.trimLeft();
    if (trimmed.isEmpty) {
      flush();
    } else if (trimmed.startsWith('#')) {
      flush();
      final level = trimmed.indexOf(' ');
      blocks.add(LegalHeading(_plain(trimmed.substring(level + 1)), level: level.clamp(1, 3)));
    } else if (trimmed.startsWith('>')) {
      note.add(trimmed.substring(1).trim());
    } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      flush();
      blocks.add(LegalBullet(_plain(trimmed.substring(2))));
    } else if (trimmed.startsWith('|')) {
      flush();
      if (_tableSeparator.hasMatch(trimmed)) continue;
      final cells = trimmed.split('|').map(_plain).where((c) => c.isNotEmpty).toList();
      if (cells.isNotEmpty) blocks.add(LegalBullet(cells.join(' — ')));
    } else {
      paragraph.add(trimmed);
    }
  }
  flush();
  return blocks;
}
