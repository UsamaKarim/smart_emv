import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_emv/src/core/emv_tag_mapper.dart';
import 'package:smart_emv/src/models/tlv_node.dart';
import 'package:smart_emv/src/utils/hex_utils.dart';

void main() {
  group('EmvTagMapper Unit Tests', () {
    test('Should parse tag 5A and map to formatted PAN', () {
      final accumulator = <String, String>{};
      final node = TlvNode(
        tag: 0x5A,
        length: 8,
        value: HexUtils.hexToBytes('4111111111111111'),
        isConstructed: false,
      );

      EmvTagMapper.mapTagData(node, accumulator);
      expect(accumulator['pan'], equals('4111 1111 1111 1111'));
    });

    test('Should parse tag 5F24 and map to formatted Expiry', () {
      final accumulator = <String, String>{};
      final node = TlvNode(
        tag: 0x5F24,
        length: 3,
        value: HexUtils.hexToBytes('271231'), // Dec 31, 2027
        isConstructed: false,
      );

      EmvTagMapper.mapTagData(node, accumulator);
      expect(accumulator['expiry'], equals('12/27'));
    });

    test('Should parse tag 5F20 and map to cardholder name', () {
      final accumulator = <String, String>{};
      final nameBytes = Uint8List.fromList(ascii.encode(' JOHN DOE '));
      final node = TlvNode(
        tag: 0x5F20,
        length: nameBytes.length,
        value: nameBytes,
        isConstructed: false,
      );

      EmvTagMapper.mapTagData(node, accumulator);
      expect(accumulator['cardholder'], equals('JOHN DOE'));
    });

    test('Should parse Track 2 (tag 57) and extract PAN/Expiry fallback', () {
      final accumulator = <String, String>{};
      // Track 2 format: PAN + 'D' + Expiry (YYMM) + Service Code + Discretionary Data
      final track2Bytes = HexUtils.hexToBytes(
        '4111111111111111D2812101000000000F',
      );
      final node = TlvNode(
        tag: 0x57,
        length: track2Bytes.length,
        value: track2Bytes,
        isConstructed: false,
      );

      EmvTagMapper.mapTagData(node, accumulator);
      expect(accumulator['pan'], equals('4111 1111 1111 1111'));
      expect(accumulator['expiry'], equals('12/28'));
    });

    test(
      'Should parse Track 1 (tag 56) and extract cardholder name fallback',
      () {
        final accumulator = <String, String>{};
        const track1Str = 'B4111111111111111^DOE/JOHN^2812101000';
        final track1Bytes = Uint8List.fromList(ascii.encode(track1Str));
        final node = TlvNode(
          tag: 0x56,
          length: track1Bytes.length,
          value: track1Bytes,
          isConstructed: false,
        );

        EmvTagMapper.mapTagData(node, accumulator);
        expect(accumulator['cardholder'], equals('DOE/JOHN'));
      },
    );
  });
}
