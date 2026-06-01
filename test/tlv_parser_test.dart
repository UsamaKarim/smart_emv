import 'package:flutter_test/flutter_test.dart';
import 'package:smart_emv/src/core/tlv_parser.dart';
import 'package:smart_emv/src/utils/hex_utils.dart';

void main() {
  group('TlvParser Unit Tests', () {
    test('Should parse simple primitive tag correctly', () {
      // Primitive Tag 50 (Application Label) with length 4: "VISA" (56 49 53 41)
      final rawData = HexUtils.hexToBytes(
        '5004564953419000',
      ); // Including successful status words
      final node = TlvParser.parse(rawData);

      expect(node, isNotNull);
      expect(node!.tag, equals(0x50));
      expect(node.length, equals(4));
      expect(HexUtils.bytesToHex(node.value), equals('56495341'));
      expect(node.children, isEmpty);
      expect(node.isConstructed, isFalse);
    });

    test(
      'Should parse constructed tags with nested child nodes recursively',
      () {
        // Template Tag 6F (FCI Template) length 12 containing:
        // Tag 84 (DF Name) length 7 (A0000000031010)
        // Tag 50 (App Label) length 1 (56)
        final rawData = HexUtils.hexToBytes('6F0C8407A00000000310105001569000');
        final node = TlvParser.parse(rawData);

        expect(node, isNotNull);
        expect(node!.tag, equals(0x6F));
        expect(node.isConstructed, isTrue);
        expect(node.children.length, equals(2));

        final dfNameNode = node.find(0x84);
        expect(dfNameNode, isNotNull);
        expect(dfNameNode!.length, equals(7));
        expect(HexUtils.bytesToHex(dfNameNode.value), equals('A0000000031010'));

        final appLabelNode = node.find(0x50);
        expect(appLabelNode, isNotNull);
        expect(appLabelNode!.length, equals(1));
      },
    );

    test('Should parse multi-byte tags correctly', () {
      // Multi-byte Tag 9F36 (ATC) length 2: 00 12
      final rawData = HexUtils.hexToBytes('9F360200129000');
      final node = TlvParser.parse(rawData);

      expect(node, isNotNull);
      expect(node!.tag, equals(0x9F36));
      expect(node.length, equals(2));
      expect(HexUtils.bytesToHex(node.value), equals('0012'));
    });

    test('Should parse multi-byte length fields correctly (0x81 prefix)', () {
      // Primitive Tag 50 (App Label) with multi-byte length representation (0x81, 0x04)
      final rawData = HexUtils.hexToBytes('508104564953419000');
      final node = TlvParser.parse(rawData);

      expect(node, isNotNull);
      expect(node!.tag, equals(0x50));
      expect(node.length, equals(4));
      expect(HexUtils.bytesToHex(node.value), equals('56495341'));
    });

    test('Should return null or stop on malformed truncated data safely', () {
      // Tag 50 declares length 10 but packet only provides 4 bytes of value
      final rawData = HexUtils.hexToBytes('500A564953419000');
      final node = TlvParser.parse(rawData);
      expect(node, isNull);
    });

    test(
      'Should locate all matching nested tags recursively using findAll()',
      () {
        // Tag 6F containing multiple occurrences of Tag 50
        final rawData = HexUtils.hexToBytes('6F095001415001425001439000');
        final node = TlvParser.parse(rawData);

        expect(node, isNotNull);
        final found = node!.findAll(0x50);
        expect(found.length, equals(3));
        expect(HexUtils.bytesToHex(found[0].value), equals('41'));
        expect(HexUtils.bytesToHex(found[1].value), equals('42'));
        expect(HexUtils.bytesToHex(found[2].value), equals('43'));
      },
    );
  });
}
