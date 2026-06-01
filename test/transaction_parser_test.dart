import 'package:flutter_test/flutter_test.dart';
import 'package:smart_emv/src/core/transaction_parser.dart';
import 'package:smart_emv/src/utils/emv_logger.dart';
import 'mocks/mock_transceiver.dart';

void main() {
  group('TransactionParser Unit Tests', () {
    test(
      'Should parse transaction record with dynamic formats correctly',
      () async {
        final mock = MockTransceiver();

        // Log Entry configuration: SFI 3, Record count 1 (Hex: '0301')
        const logEntryHex = '0301';

        // Log Format specification:
        // Date: Tag 9A length 3 (Hex: '9A03')
        // Time: Tag 9F21 length 3 (Hex: '9F2103')
        // Amount: Tag 9F02 length 6 (Hex: '9F0206')
        // Currency: Tag 5F2A length 2 (Hex: '5F2A02')
        // Type: Tag 9C length 1 (Hex: '9C01')
        const logFormatHex = '9A039F21039F02065F2A029C01';

        // SFI 3 Record 1 Read command: 00B2011C00
        // Mock Response contains:
        // Date: 260601 (June 1, 2026)
        // Time: 123045 (12:30:45)
        // Amount: 000000005000 ($50.00)
        // Currency: 0840 (USD)
        // Type: 00 (Purchase)
        // SW1/SW2: 9000
        mock.addResponse('00B2011C00', '2606011230450000000050000840009000');

        final txs = await TransactionParser.readTransactions(
          transceiver: mock,
          logEntryHex: logEntryHex,
          logFormatHex: logFormatHex,
          logger: const EmvLogger(enabled: false),
        );

        expect(txs, isNotEmpty);
        expect(txs.length, equals(1));

        final tx = txs.first;
        expect(tx.date, equals('26/06/01'));
        expect(tx.time, equals('12:30:45'));
        expect(tx.amount, equals('50.00'));
        expect(tx.currency, equals('0840'));
        expect(tx.type, equals('00'));
        expect(
          tx.toString(),
          equals(
            'Date: 26/06/01, Time: 12:30:45, Amt: 50.00, Cur: 0840, Type: 00',
          ),
        );
      },
    );

    test('Should fall back to raw hex if log format layout is empty', () async {
      final mock = MockTransceiver();

      const logEntryHex = '0301';
      const logFormatHex = ''; // Empty format list

      mock.addResponse('00B2011C00', '01020304059000');

      final txs = await TransactionParser.readTransactions(
        transceiver: mock,
        logEntryHex: logEntryHex,
        logFormatHex: logFormatHex,
        logger: const EmvLogger(enabled: false),
      );

      expect(txs, isNotEmpty);
      expect(txs.first.raw, equals('0102030405'));
      expect(txs.first.toString(), equals('RAW:0102030405'));
    });
  });
}
