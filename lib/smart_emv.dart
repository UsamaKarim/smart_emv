// Main Public Interface & Configurations
export 'src/smart_emv.dart';
export 'src/smart_emv_config.dart';

// Public Data Models
export 'src/models/emv_card.dart';
export 'src/models/emv_transaction.dart';
export 'src/models/emv_aid.dart';
export 'src/models/terminal_config.dart';
export 'src/models/tlv_node.dart';
export 'src/models/apdu_response.dart';
export 'src/models/smart_emv_exception.dart';

// Public Transport Interface (useful if users inject custom transceiver layers)
export 'src/transport/nfc_transceiver.dart';
export 'src/transport/flutter_nfc_kit_transceiver.dart';
