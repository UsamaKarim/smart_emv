import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:smart_emv/smart_emv.dart';

void main() {
  runApp(const MyApp());
}

/// Main entry widget for the Smart EMV reader demonstration application.
class MyApp extends StatefulWidget {
  /// Creates a [MyApp] instance.
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Ready to scan';
  EmvCard? _card;
  bool _isScanning = false;

  // Instantiate SmartEmv with debug logging enabled
  final _smartEmv = SmartEmv(
    config: const SmartEmvConfig(
      enableLogging: true,
      iosAlertMessage: 'Approach an EMV payment card to the back of the phone.',
    ),
  );

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _status = 'Approach an EMV card to the back of the phone';
      _card = null;
    });

    try {
      // 1. Verify NFC availability
      final available = await _smartEmv.isNfcAvailable();
      if (!available) {
        setState(() {
          _status = 'NFC is not available or turned off in settings.';
          _isScanning = false;
        });
        return;
      }

      // 2. Poll and read the card details
      final cardResult = await _smartEmv.readCard();

      setState(() {
        _card = cardResult;
        _status = 'Card read successfully!';
      });
    } on SmartEmvException catch (e) {
      setState(() {
        _status = 'NFC Scan Failed: ${e.message}';
        developer.log(e.toString());
      });
    } catch (e) {
      setState(() {
        _status = 'Error scanning card: $e';
        developer.log(e.toString());
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.tealAccent,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SmartEMV NFC Reader'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_card != null) ...[
                _buildCreditCard(),
                const SizedBox(height: 24),
                _buildDataSection('Cardholder Info', [
                  _buildDataRow(
                    'Cardholder Name',
                    _card!.cardholderName ?? 'N/A',
                  ),
                  _buildDataRow(
                    'Preferred Name',
                    _card!.preferredName ?? 'N/A',
                  ),
                  _buildDataRow('Preferred Language', _card!.language ?? 'N/A'),
                  _buildDataRow('Issuer Country', _card!.countryCode ?? 'N/A'),
                ]),
                const SizedBox(height: 16),
                _buildDataSection('Bank & App Details', [
                  _buildDataRow('App Label', _card!.label ?? 'N/A'),
                  _buildDataRow('AID Selected', _card!.aid ?? 'N/A'),
                  _buildDataRow('IBAN', _card!.iban ?? 'N/A'),
                  _buildDataRow('BIC', _card!.bic ?? 'N/A'),
                  _buildDataRow(
                    'PAN Sequence Num',
                    _card!.panSequenceNumber ?? 'N/A',
                  ),
                  _buildDataRow('App Currency', _card!.currencyCode ?? 'N/A'),
                ]),
                const SizedBox(height: 16),
                _buildDataSection('Security Metrics', [
                  _buildDataRow(
                    'Transaction Count (ATC)',
                    _card!.atc?.toString() ?? 'N/A',
                  ),
                  _buildDataRow(
                    'PIN Tries Remaining',
                    _card!.pinTriesRemaining?.toString() ?? 'N/A',
                  ),
                  _buildDataRow(
                    'Last Online ATC',
                    _card!.lastOnlineAtc?.toString() ?? 'N/A',
                  ),
                  _buildDataRow('Form Factor', _card!.formFactor ?? 'N/A'),
                  _buildDataRow(
                    'Offline Balance',
                    _card!.offlineBalance ?? 'N/A',
                  ),
                  _buildDataRow(
                    'Default Action (ADA)',
                    _card!.applicationDefaultAction ?? 'N/A',
                  ),
                  _buildDataRow(
                    'Transaction Qualifiers',
                    _card!.cardTransactionQualifiers ?? 'N/A',
                  ),
                  _buildDataRow(
                    'Issuer Application Data',
                    _card!.issuerData ?? 'N/A',
                  ),
                ]),
                if (_card!.transactions != null &&
                    _card!.transactions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDataSection('Transaction History', [
                    ..._card!.transactions!.map(
                      (tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tx.date ?? '--/--/--',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Colors.tealAccent,
                              ),
                            ),
                            Text(
                              '${tx.amount ?? 'N/A'} ${tx.currency ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ],
              ] else
                _buildScanPlaceholder(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: const Icon(Icons.nfc),
                label: Text(_isScanning ? 'SCANNING...' : 'SCAN PAYMENT CARD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _card!.label?.toUpperCase() ?? 'CREDIT CARD',
                style: const TextStyle(
                  letterSpacing: 2,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
              const Icon(Icons.contactless, color: Colors.tealAccent, size: 28),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            _card!.pan ?? '**** **** **** ****',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFamily: 'monospace',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _card!.expiry ?? '--/--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CARDHOLDER',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _card!.cardholderName ?? 'VALUED CUSTOMER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
              color: Colors.blueAccent,
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanPlaceholder() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nfc,
              size: 56,
              color: _isScanning ? Colors.blueAccent : Colors.white24,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
