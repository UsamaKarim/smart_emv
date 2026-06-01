import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_emv/src/utils/hex_utils.dart';

void main() {
  group('HexUtils Unit Tests', () {
    test('hexToBytes should convert hex string to Uint8List correctly', () {
      const hex = '00A404000E';
      final bytes = HexUtils.hexToBytes(hex);
      expect(bytes, equals(Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x0E])));
    });

    test('hexToBytes should ignore space formatting', () {
      const hex = '00 A4 04 00 0E';
      final bytes = HexUtils.hexToBytes(hex);
      expect(bytes, equals(Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x0E])));
    });

    test('hexToBytes should throw on odd-length hex strings', () {
      expect(() => HexUtils.hexToBytes('0'), throwsArgumentError);
      expect(() => HexUtils.hexToBytes('ABC'), throwsArgumentError);
    });

    test('hexToBytes should throw on non-hexadecimal characters', () {
      expect(() => HexUtils.hexToBytes('0G'), throwsFormatException);
      expect(() => HexUtils.hexToBytes('123Z'), throwsFormatException);
    });

    test('bytesToHex should convert bytes back to uppercase hex string', () {
      final bytes = Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x0E]);
      final hex = HexUtils.bytesToHex(bytes);
      expect(hex, equals('00A404000E'));
    });

    test('bytesToHex should return empty string for empty input', () {
      expect(HexUtils.bytesToHex(Uint8List(0)), isEmpty);
    });

    test('formatPan should split primary account digits with spaces', () {
      const pan = '4111111111111111';
      expect(HexUtils.formatPan(pan), equals('4111 1111 1111 1111'));
    });

    test(
      'formatExpiry should parse card hex format into standard expiry layout',
      () {
        const rawHex = '2612'; // Dec 2026
        expect(HexUtils.formatExpiry(rawHex), equals('12/26'));
      },
    );
  });
}
