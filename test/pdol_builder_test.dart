import 'package:flutter_test/flutter_test.dart';
import 'package:smart_emv/src/core/pdol_builder.dart';
import 'package:smart_emv/src/models/terminal_config.dart';
import 'package:smart_emv/src/utils/hex_utils.dart';

void main() {
  group('PdolBuilder Unit Tests', () {
    test('Should parse PDOL tags correctly', () {
      // PDOL raw bytes representing:
      // Tag 9F66 length 4
      // Tag 9F1A length 2
      // Tag 9F37 length 4
      final pdolBytes = HexUtils.hexToBytes('9F66049F1A029F3704');
      final tags = PdolBuilder.parsePdolTags(pdolBytes);

      expect(tags.length, equals(3));
      expect(tags[0].tag, equals(0x9F66));
      expect(tags[0].length, equals(4));
      expect(tags[1].tag, equals(0x9F1A));
      expect(tags[1].length, equals(2));
      expect(tags[2].tag, equals(0x9F37));
      expect(tags[2].length, equals(4));
    });

    test(
      'Should construct correct PDOL response with filled values from config',
      () {
        final pdolBytes = HexUtils.hexToBytes('9F66049F1A029F3501');
        const config = TerminalConfig(
          countryCode: '0840', // USA BCD
          currencyCode: '0840', // USD BCD
          terminalCapabilities: 'E0A000',
          terminalType: '22',
          transactionQualifiers: 'F620C000',
          additionalTerminalCapabilities: '8E00B05005',
          interfaceDeviceSerialNumber: '3031323334353637',
        );

        final res = PdolBuilder.buildPdolResponse(pdolBytes, config);
        final resHex = HexUtils.bytesToHex(res);

        // 9F66 (4 bytes TTQ) -> F620C000
        // 9F1A (2 bytes Country) -> 0840
        // 9F35 (1 byte Type) -> 22
        expect(resHex, equals('F620C000084022'));
      },
    );
  });
}
