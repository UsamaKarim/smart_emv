import 'package:flutter_test/flutter_test.dart';
import 'package:smart_emv/src/core/apdu_command.dart';
import 'package:smart_emv/src/utils/hex_utils.dart';

void main() {
  group('ApduCommand Unit Tests', () {
    test('selectPpse should build correct PPSE select command', () {
      final cmd = ApduCommand.selectPpse();
      expect(
        HexUtils.bytesToHex(cmd),
        equals('00A404000E325041592E5359532E444446303100'),
      );
    });

    test('selectAid should build correct AID select command', () {
      const aid = 'A0000000031010';
      final cmd = ApduCommand.selectAid(aid);
      expect(HexUtils.bytesToHex(cmd), equals('00A4040007A000000003101000'));
    });

    test(
      'readRecord should construct correct read command with calculated SFI parameter',
      () {
        const sfi = 2;
        const record = 1;
        final cmd = ApduCommand.readRecord(sfi, record);
        // p2 = (2 << 3) | 4 = 16 | 4 = 20 (0x14)
        expect(HexUtils.bytesToHex(cmd), equals('00B2011400'));
      },
    );

    test('getData should build correct GET DATA command for requested tag', () {
      const tag = 0x9F36;
      final cmd = ApduCommand.getData(tag);
      expect(HexUtils.bytesToHex(cmd), equals('80CA9F3600'));
    });

    test(
      'getProcessingOptions should build correct dynamic GPO APDU command bytes',
      () {
        final pdolData = HexUtils.hexToBytes('F620C000084022');
        final cmd = ApduCommand.getProcessingOptions(pdolData);
        // 80 A8 00 00 [len=09] 83 07 F6 20 C0 00 08 40 22 00
        expect(
          HexUtils.bytesToHex(cmd),
          equals('80A80000098307F620C00008402200'),
        );
      },
    );

    test(
      'getFallbackGpo should build correct empty fallback GPO APDU command bytes',
      () {
        final cmd = ApduCommand.getFallbackGpo();
        expect(HexUtils.bytesToHex(cmd), equals('80A8000002830000'));
      },
    );
  });
}
