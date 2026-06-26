import 'call_center_model.dart';

class ChatApiResponse {
  final String response;
  final String riskLevel;
  final bool showCallCenter;
  final String? alertId;
  final List<CallCenterService>? callCenterServices;

  ChatApiResponse({
    required this.response,
    required this.riskLevel,
    required this.showCallCenter,
    this.alertId,
    this.callCenterServices,
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    return ChatApiResponse(
      response: json['response'] as String,
      riskLevel: json['riskLevel'] as String,
      showCallCenter: json['showCallCenter'] as bool? ?? false,
      alertId: json['alertId'] as String?,
      callCenterServices: json['callCenterServices'] != null
          ? (json['callCenterServices'] as List)
              .map((s) => CallCenterService.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}
