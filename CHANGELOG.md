## 0.0.1

* Initial release of `smart_emv`.
* Complete pure Dart port of the Android-only Kotlin `emv_nfc_reader` plugin.
* Cross-platform support for both Android & iOS using unified NFC ISO-7816 transceive APDUs.
* Dynamic terminal parameter customization and PDOL configurations (defaulting to USA/USD).
* Recursive BER-TLV parser, dynamic PDOL builder, and AFL record loop directly in Dart.
* Typed `EmvCard` and `EmvTransaction` models with backwards-compatible `toMap()` maps.
* Extensive offline unit tests suite using mocked smart-card transceivers.
