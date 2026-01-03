import 'vulnerability_type.dart';

/// Result of a security check
class SecurityCheckResult {
  final VulnerabilityType type;
  final bool isVulnerable;
  final String message;
  final Map<String, dynamic>? details;

  SecurityCheckResult({
    required this.type,
    required this.isVulnerable,
    required this.message,
    this.details,
  });

  factory SecurityCheckResult.fromMap(Map<String, dynamic> map) {
    return SecurityCheckResult(
      type: VulnerabilityType.values.firstWhere(
            (e) => e.toString() == 'VulnerabilityType.${map['type']}',
        orElse: () => VulnerabilityType.unknown,
      ),
      isVulnerable: map['isVulnerable'] ?? false,
      message: map['message'] ?? '',
      details: map['details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'isVulnerable': isVulnerable,
      'message': message,
      'details': details,
    };
  }
}

/// Complete security report
class SecurityReport {
  final List<SecurityCheckResult> results;
  final DateTime timestamp;
  final int totalChecks;
  final int vulnerabilitiesFound;

  SecurityReport({
    required this.results,
    required this.timestamp,
    required this.totalChecks,
    required this.vulnerabilitiesFound,
  });

  bool get isSecure => vulnerabilitiesFound == 0;

  List<SecurityCheckResult> get vulnerabilities =>
      results.where((r) => r.isVulnerable).toList();
}