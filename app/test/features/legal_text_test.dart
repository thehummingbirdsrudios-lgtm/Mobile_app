import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/features/settings/domain/legal_text.dart';

void main() {
  test('parses headings, notes, bullets, tables and paragraphs', () {
    final blocks = parseLegalMarkdown('''
# Title

> **Status: draft.**
> Second line.

## 2. What

| What | Why |
|---|---|
| Account | **Sign in** |

- one
Para line one
line two.
''');
    expect(blocks.map((b) => b.runtimeType.toString()), [
      'LegalHeading',
      'LegalNote',
      'LegalHeading',
      'LegalBullet',
      'LegalBullet',
      'LegalBullet',
      'LegalParagraph',
    ]);
    expect((blocks[0] as LegalHeading).level, 1);
    expect(blocks[1].text, 'Status: draft. Second line.');
    expect(blocks[3].text, 'What — Why');
    expect(blocks[4].text, 'Account — Sign in');
    expect(blocks.last.text, 'Para line one line two.');
  });

  test('empty input yields no blocks', () => expect(parseLegalMarkdown(''), isEmpty));
}
