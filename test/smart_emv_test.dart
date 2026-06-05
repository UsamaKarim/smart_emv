import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_emv/smart_emv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartEmv NFC session cleanup', () {
    const nfcChannel = MethodChannel('flutter_nfc_kit/method');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nfcChannel, null);
    });

    test(
      'finishes NFC session when poll fails before transceiver exists',
      () async {
        final methodCalls = <String>[];

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(nfcChannel, (call) async {
              methodCalls.add(call.method);

              switch (call.method) {
                case 'getNFCAvailability':
                  return 'available';
                case 'poll':
                  throw PlatformException(
                    code: '500',
                    message: 'Error connecting to card',
                  );
                case 'finish':
                  return null;
              }

              fail('Unexpected NFC method call: ${call.method}');
            });

        final smartEmv = SmartEmv();

        await expectLater(
          smartEmv.readCard(),
          throwsA(
            isA<SmartEmvException>().having(
              (e) => e.code,
              'code',
              SmartEmvErrorCode.connectionFailed,
            ),
          ),
        );

        expect(
          methodCalls,
          containsAllInOrder(['getNFCAvailability', 'poll', 'finish']),
        );
      },
    );
  });

  group('SmartEmv Instantiation and Config Tests', () {
    test('SmartEmv instantiates with default config', () {
      final smartEmv = SmartEmv();
      expect(smartEmv, isNotNull);
      expect(smartEmv.config.timeoutSeconds, equals(30));
      expect(smartEmv.config.enableLogging, isFalse);
      expect(smartEmv.config.readTransactions, isTrue);
      expect(smartEmv.config.fetchAdditionalData, isTrue);
      expect(smartEmv.config.customAids, isNull);
      expect(smartEmv.config.customTransceiver, isNull);
    });

    test('SmartEmv accepts and preserves custom config values', () {
      final smartEmv = SmartEmv(
        config: const SmartEmvConfig(
          enableLogging: true,
          timeoutSeconds: 60,
          readTransactions: false,
          fetchAdditionalData: false,
          iosAlertMessage: 'Custom message',
        ),
      );
      expect(smartEmv.config.enableLogging, isTrue);
      expect(smartEmv.config.timeoutSeconds, equals(60));
      expect(smartEmv.config.readTransactions, isFalse);
      expect(smartEmv.config.fetchAdditionalData, isFalse);
      expect(smartEmv.config.iosAlertMessage, equals('Custom message'));
    });

    test('SmartEmvConfig.defaultConfig() has correct default values', () {
      const config = SmartEmvConfig.defaultConfig();
      expect(config.timeoutSeconds, equals(30));
      expect(config.enableLogging, isFalse);
      expect(config.readTransactions, isTrue);
      expect(config.fetchAdditionalData, isTrue);
      expect(config.customAids, isNull);
      expect(config.customTransceiver, isNull);
      expect(
        config.terminalConfig.countryCode,
        equals('0840'),
      ); // USA ISO 3166-1
      expect(
        config.terminalConfig.currencyCode,
        equals('0840'),
      ); // USD ISO 4217
      // Default flags: FLAG_READER_SKIP_NDEF_CHECK (0x80) | FLAG_READER_NO_PLATFORM_SOUNDS (0x100)
      expect(config.androidReaderModeFlags, equals(0x80 | 0x100));
    });

    test(
      'SmartEmvConfig androidReaderModeFlags can be set to zero (platform default)',
      () {
        const config = SmartEmvConfig(androidReaderModeFlags: 0);
        expect(config.androidReaderModeFlags, equals(0));
      },
    );

    test(
      'SmartEmvConfig androidReaderModeFlags can be set to custom value',
      () {
        // Only skip NDEF, keep system sounds
        const config = SmartEmvConfig(androidReaderModeFlags: 0x80);
        expect(config.androidReaderModeFlags, equals(0x80));
      },
    );
  });

  group('EmvCard Equality and copyWith Tests', () {
    const baseCard = EmvCard(
      pan: '4111 1111 1111 1111',
      expiry: '12/27',
      cardholderName: 'JOHN DOE',
      label: 'VISA DEBIT',
      aid: 'A0000000031010',
      atc: 21,
    );

    test('EmvCard.== returns true for identical cards', () {
      const card2 = EmvCard(
        pan: '4111 1111 1111 1111',
        expiry: '12/27',
        cardholderName: 'JOHN DOE',
        label: 'VISA DEBIT',
        aid: 'A0000000031010',
        atc: 21,
      );
      expect(baseCard, equals(card2));
    });

    test('EmvCard.== returns false when pan differs', () {
      final card2 = baseCard.copyWith(pan: '5500 0000 0000 0004');
      expect(baseCard, isNot(equals(card2)));
    });

    test('EmvCard.copyWith replaces only specified fields', () {
      final updated = baseCard.copyWith(expiry: '06/30', atc: 42);
      expect(updated.pan, equals(baseCard.pan));
      expect(updated.cardholderName, equals(baseCard.cardholderName));
      expect(updated.expiry, equals('06/30'));
      expect(updated.atc, equals(42));
    });

    test('EmvCard.== performs deep equality on transactions list', () {
      const tx1 = EmvTransaction(
        date: '26/06/01',
        amount: '50.00',
        currency: '0840',
      );
      final card1 = baseCard.copyWith(transactions: [tx1]);
      final card2 = baseCard.copyWith(
        transactions: [
          const EmvTransaction(
            date: '26/06/01',
            amount: '50.00',
            currency: '0840',
          ),
        ],
      );
      final cardDiff = baseCard.copyWith(
        transactions: [
          const EmvTransaction(
            date: '25/01/10',
            amount: '10.00',
            currency: '0840',
          ),
        ],
      );

      // Same transaction content should be equal
      expect(card1, equals(card2));
      // Different transaction content should not be equal
      expect(card1, isNot(equals(cardDiff)));
    });

    test('EmvCard.== performs deep equality on rawTags map', () {
      final card1 = baseCard.copyWith(
        rawTags: {'9F36': '0015', '50': '5649534120444542495'},
      );
      final card2 = baseCard.copyWith(
        rawTags: {'9F36': '0015', '50': '5649534120444542495'},
      );
      final cardDiff = baseCard.copyWith(rawTags: {'9F36': '0099'});

      expect(card1, equals(card2));
      expect(card1, isNot(equals(cardDiff)));
    });
  });

  group('EmvTransaction Equality and copyWith Tests', () {
    const tx = EmvTransaction(
      date: '26/06/01',
      time: '12:30:45',
      amount: '50.00',
      currency: '0840',
      type: '00',
    );

    test('EmvTransaction.== returns true for identical transactions', () {
      const tx2 = EmvTransaction(
        date: '26/06/01',
        time: '12:30:45',
        amount: '50.00',
        currency: '0840',
        type: '00',
      );
      expect(tx, equals(tx2));
    });

    test('EmvTransaction.== returns false when amount differs', () {
      final tx2 = tx.copyWith(amount: '100.00');
      expect(tx, isNot(equals(tx2)));
    });

    test('EmvTransaction.copyWith replaces only specified fields', () {
      final updated = tx.copyWith(amount: '99.99', currency: '0978');
      expect(updated.date, equals(tx.date));
      expect(updated.time, equals(tx.time));
      expect(updated.amount, equals('99.99'));
      expect(updated.currency, equals('0978'));
    });

    test(
      'EmvTransaction.toString returns formatted string for parsed records',
      () {
        final result = tx.toString();
        expect(result, contains('26/06/01'));
        expect(result, contains('50.00'));
      },
    );

    test('EmvTransaction.toString returns RAW: for unformatted records', () {
      const rawTx = EmvTransaction(raw: 'DEADBEEF');
      expect(rawTx.toString(), equals('RAW:DEADBEEF'));
    });
  });
}
