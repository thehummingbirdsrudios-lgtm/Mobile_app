import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Minimal reader for the PDFs this app writes (uncompressed object table,
/// Flate content streams, raw DCT image streams). Lets tests check what is
/// really inside a generated PDF: pages, images, and which image each page
/// draws in which order.
class PdfInspection {
  PdfInspection(this.bytes) {
    final text = latin1.decode(bytes);
    for (final m in RegExp(r'(\d+) 0 obj').allMatches(text)) {
      final number = int.parse(m.group(1)!);
      final start = m.end;
      final end = text.indexOf('endobj', start);
      final body = text.substring(start, end);
      final streamAt = body.indexOf('stream');
      final dict = streamAt < 0 ? body : body.substring(0, streamAt);
      Uint8List? stream;
      if (streamAt >= 0) {
        final length = int.parse(RegExp(r'/Length (\d+)').firstMatch(dict)!.group(1)!);
        var dataStart = start + streamAt + 'stream'.length;
        if (text[dataStart] == '\r') dataStart++;
        if (text[dataStart] == '\n') dataStart++;
        stream = Uint8List.sublistView(bytes, dataStart, dataStart + length);
      }
      _objects[number] = (dict: dict, stream: stream);
    }
  }

  final Uint8List bytes;
  final _objects = <int, ({String dict, Uint8List? stream})>{};

  int get size => bytes.length;

  bool get isPdf => latin1.decode(bytes.sublist(0, 5)) == '%PDF-';

  /// Page object numbers in reading order.
  List<int> get pages {
    final root = _objects.values.firstWhere((o) => o.dict.contains('/Type/Pages'));
    final kids = RegExp(r'/Kids\[(.*?)\]').firstMatch(root.dict)!.group(1)!;
    return [for (final m in RegExp(r'(\d+) 0 R').allMatches(kids)) int.parse(m.group(1)!)];
  }

  /// Every image XObject: object number → (width, height, filter, bytes).
  Map<int, ({int width, int height, String filter, Uint8List data})> get images => {
    for (final e in _objects.entries)
      if (e.value.dict.contains('/Subtype/Image'))
        e.key: (
          width: int.parse(RegExp(r'/Width (\d+)').firstMatch(e.value.dict)!.group(1)!),
          height: int.parse(RegExp(r'/Height (\d+)').firstMatch(e.value.dict)!.group(1)!),
          filter: RegExp(r'/Filter/(\w+)').firstMatch(e.value.dict)?.group(1) ?? '',
          data: e.value.stream!,
        ),
  };

  /// Image objects drawn on [page], in drawing order.
  List<int> imagesDrawnOn(int page) {
    final dict = _objects[page]!.dict;
    final names = {for (final m in RegExp(r'/(I\d+) (\d+) 0 R').allMatches(dict)) m.group(1)!: int.parse(m.group(2)!)};
    final contents = RegExp(r'/Contents (\d+) 0 R').firstMatch(dict)!.group(1)!;
    final obj = _objects[int.parse(contents)]!;
    final raw = obj.dict.contains('/FlateDecode') ? ZLibCodec().decode(obj.stream!) : obj.stream!;
    final ops = latin1.decode(raw);
    return [for (final m in RegExp(r'/(I\d+)\s+Do').allMatches(ops)) ?names[m.group(1)!]];
  }

  /// All images drawn, page by page, in order.
  List<int> get imagesDrawn => [for (final p in pages) ...imagesDrawnOn(p)];
}
