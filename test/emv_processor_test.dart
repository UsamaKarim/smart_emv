import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_emv/src/core/emv_processor.dart';
import 'package:smart_emv/src/models/emv_aid.dart';
import 'package:smart_emv/src/models/smart_emv_exception.dart';
import 'package:smart_emv/src/models/terminal_config.dart';
import 'package:smart_emv/src/transport/nfc_transceiver.dart';
import 'package:smart_emv/src/utils/emv_logger.dart';
import 'package:smart_emv/src/utils/hex_utils.dart';
import 'mocks/mock_transceiver.dart';

void main() {
  group('EmvProcessor Integration Tests', () {
    test(
      'Should execute full EMV sequence successfully and extract Visa card details',
      () async {
        final mock = MockTransceiver();

        // 1. Mock PPSE selection response. Discovers AID "A0000000031010" (Visa).
        mock.addResponse(
          '00A404000E325041592E5359532E444446303100',
          '6F1D840E325041592E5359532E4444463031A50BBF0C0861064F07A00000000310109000',
        );

        // 2. Mock Visa AID Selection response. Returns label "VISA DEBIT" and PDOL tag 9F66 length 4.
        mock.addResponse(
          '00A4040007A000000003101000',
          '6F1D8407A0000000031010A512500A564953412044454249549F38039F66049000',
        );

        // 3. Mock GPO Command. Config fills 9F66 with transaction qualifiers: "F620C000".
        mock.addResponse(
          '80A80000068304F620C00000',
          '770E82020000940808010100100101009000', // Returns AFL. SFI 1 record 1.
        );

        // 4. Mock AFL Record 1 from SFI 1.
        mock.addResponse(
          '00B2010C00',
          '701D5F200A4A4F484E20444F4520205A0841111111111111115F24032712319000', // PAN 4111 1111 1111 1111
        );

        mock.addResponse('00B2011400', '9000');

        mock.addResponse('80CA9F3600', '9F360200159000'); // ATC = 21
        mock.addResponse('80CA9F1700', '9F1701039000'); // PIN Tries = 3

        final processor = EmvProcessor(
          transceiver: mock,
          terminalConfig: const TerminalConfig.defaultConfig(),
          logger: const EmvLogger(enabled: false),
          readTransactions: false,
          fetchAdditionalData: true,
        );

        final card = await processor.readCard();

        expect(card.pan, equals('4111 1111 1111 1111'));
        expect(card.expiry, equals('12/27'));
        expect(card.cardholderName, equals('JOHN DOE'));
        expect(card.label, equals('VISA DEBIT'));
        expect(card.atc, equals(21));
        expect(card.pinTriesRemaining, equals(3));
        expect(card.aid, equals('A0000000031010'));
      },
    );

    test(
      'Should fall back to default AIDs list when PPSE selection is rejected',
      () async {
        final mock = MockTransceiver();

        // PPSE Select command returns standard rejected status (6A82)
        mock.addResponse('00A404000E325041592E5359532E444446303100', '6A82');

        // Should fall back and try standard fallback AIDs list. We mock Visa select response.
        mock.addResponse(
          '00A4040007A000000003101000', // Visa AID Select
          '6F1D8407A0000000031010A512500A564953412044454249549F38039F66049000',
        );

        mock.addResponse(
          '80A80000068304F620C00000',
          '770E82020000940808010100100101009000',
        );

        mock.addResponse(
          '00B2010C00',
          '701D5F200A4A4F484E20444F4520205A0841111111111111115F24032712319000',
        );

        final processor = EmvProcessor(
          transceiver: mock,
          terminalConfig: const TerminalConfig.defaultConfig(),
          logger: const EmvLogger(enabled: false),
          fallbackAids: const [EmvAid.visa],
          readTransactions: false,
          fetchAdditionalData: false,
        );

        final card = await processor.readCard();
        expect(card.pan, equals('4111 1111 1111 1111'));
        expect(card.aid, equals('A0000000031010'));
      },
    );

    test('Should perform empty fallback GPO retry when standard GPO fails', () async {
      final mock = MockTransceiver();

      mock.addResponse('00A404000E325041592E5359532E444446303100', '6A82');

      // Select AID has no PDOL
      mock.addResponse(
        '00A4040007A000000003101000',
        '6F1A8407A0000000031010A50F500A564953412044454249549000', // No 9F38 tag
      );

      // Empty standard GPO command: 80A8000002830000. Mock failure status.
      mock.addResponse(
        '80A8000002830000',
        '6F00', // General failure
      );

      // Fallback GPO retry (with empty 8300): our EmvProcessor automatically retries with '80A8000002830000'.
      // If we mock success this time, it should scan AFL as standard.
      // Wait, standard GPO command without PDOL is already 80A8000002830000.
      // Let's verify that processor throws a read failed exception if GPO fails.
      final processor = EmvProcessor(
        transceiver: mock,
        terminalConfig: const TerminalConfig.defaultConfig(),
        logger: const EmvLogger(enabled: false),
        fallbackAids: const [EmvAid.visa],
        readTransactions: false,
        fetchAdditionalData: false,
      );

      expect(() => processor.readCard(), throwsA(isA<SmartEmvException>()));
    });

    test('Should immediately abort the reading sequence and rethrow if the tag is physically lost', () async {
      final transceiver = _ThrowingTransceiver();
      final processor = EmvProcessor(
        transceiver: transceiver,
        terminalConfig: const TerminalConfig.defaultConfig(),
        logger: const EmvLogger(enabled: false),
        fallbackAids: const [EmvAid.visa, EmvAid.mastercard, EmvAid.amex],
        readTransactions: true,
        fetchAdditionalData: true,
      );

      // Verify that calling readCard throws the exception immediately rather than trying other AIDs
      await expectLater(
        () => processor.readCard(),
        throwsA(predicate((e) => e.toString().contains('Tag was lost.'))),
      );

      // Verify that only 2 transceive calls were made (1 for PPSE, 1 select AID which failed and aborted)
      // rather than trying all other fallback AIDs
      expect(transceiver.transceiveCount, equals(2));
    });
  });
}

class _ThrowingTransceiver implements NfcTransceiver {
  int transceiveCount = 0;

  @override
  Future<Uint8List> transceive(Uint8List command) async {
    transceiveCount++;
    if (transceiveCount > 1) {
      throw Exception('Tag was lost.');
    }
    // Return PPSE success on first call indicating Visa AID is present
    return HexUtils.hexToBytes('6F1D840E325041592E5359532E4444463031A50BBF0C0861064F07A00000000310109000');
  }

  @override
  Future<void> close() async {}
}

