import 'package:supabase_flutter/supabase_flutter.dart';

class RiskService {
  final SupabaseClient _client;

  RiskService(this._client);

  Future<void> reportUserChoice({
    required String alertId,
    required String userChoice,
    String? callCenterName,
  }) async {
    final body = <String, dynamic>{
      'alertId': alertId,
      'userChoice': userChoice,
    };
    if (callCenterName != null) {
      body['callCenterName'] = callCenterName;
    }

    await _client.functions.invoke(
      'risk-escalation',
      body: body,
    );
  }
}
