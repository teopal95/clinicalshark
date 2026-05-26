class ClinicalTrial {
  final String nctId;
  final String briefTitle;
  final String? officialTitle;
  final String overallStatus;
  final List<String> phases;
  final String? briefSummary;
  final List<String> conditions;
  final String? sponsorName;
  final String? minimumAge;
  final String? maximumAge;
  final String? sex;
  final String? eligibilityCriteria;
  final List<TrialLocation> locations;
  final int? enrollmentCount;
  final String? startDate;
  final String? completionDate;
  final String studyType;
  final List<String> keywords;

  const ClinicalTrial({
    required this.nctId,
    required this.briefTitle,
    this.officialTitle,
    required this.overallStatus,
    required this.phases,
    this.briefSummary,
    required this.conditions,
    this.sponsorName,
    this.minimumAge,
    this.maximumAge,
    this.sex,
    this.eligibilityCriteria,
    required this.locations,
    this.enrollmentCount,
    this.startDate,
    this.completionDate,
    required this.studyType,
    required this.keywords,
  });

  factory ClinicalTrial.fromJson(Map<String, dynamic> json) {
    final protocol = json['protocolSection'] as Map<String, dynamic>? ?? {};
    final id = protocol['identificationModule'] as Map<String, dynamic>? ?? {};
    final status = protocol['statusModule'] as Map<String, dynamic>? ?? {};
    final sponsor =
        protocol['sponsorCollaboratorsModule'] as Map<String, dynamic>? ?? {};
    final description =
        protocol['descriptionModule'] as Map<String, dynamic>? ?? {};
    final conds = protocol['conditionsModule'] as Map<String, dynamic>? ?? {};
    final design = protocol['designModule'] as Map<String, dynamic>? ?? {};
    final eligibility =
        protocol['eligibilityModule'] as Map<String, dynamic>? ?? {};
    final contacts =
        protocol['contactsLocationsModule'] as Map<String, dynamic>? ?? {};

    return ClinicalTrial(
      nctId: id['nctId'] as String? ?? '',
      briefTitle: id['briefTitle'] as String? ?? 'Untitled Study',
      officialTitle: id['officialTitle'] as String?,
      overallStatus: status['overallStatus'] as String? ?? 'UNKNOWN',
      phases: (design['phases'] as List<dynamic>? ?? [])
          .map((p) => _formatPhase(p.toString()))
          .toList(),
      briefSummary: description['briefSummary'] as String?,
      conditions: (conds['conditions'] as List<dynamic>? ?? [])
          .map((c) => c.toString())
          .toList(),
      sponsorName:
          (sponsor['leadSponsor'] as Map<String, dynamic>?)?['name'] as String?,
      minimumAge: eligibility['minimumAge'] as String?,
      maximumAge: eligibility['maximumAge'] as String?,
      sex: eligibility['sex'] as String?,
      eligibilityCriteria: eligibility['eligibilityCriteria'] as String?,
      locations: (contacts['locations'] as List<dynamic>? ?? [])
          .map((l) => TrialLocation.fromJson(l as Map<String, dynamic>))
          .toList(),
      enrollmentCount:
          (design['enrollmentInfo'] as Map<String, dynamic>?)?['count'] as int?,
      startDate:
          (status['startDateStruct'] as Map<String, dynamic>?)?['date']
              as String?,
      completionDate:
          (status['primaryCompletionDateStruct'] as Map<String, dynamic>?)?['date']
              as String?,
      studyType: design['studyType'] as String? ?? 'N/A',
      keywords: (conds['keywords'] as List<dynamic>? ?? [])
          .map((k) => k.toString())
          .toList(),
    );
  }

  static String _formatPhase(String phase) =>
      phase.replaceAll('_', ' ').replaceAll('PHASE', 'Phase ');
}

class TrialLocation {
  final String? facility;
  final String? city;
  final String? state;
  final String? country;
  final String? status;

  const TrialLocation({
    this.facility,
    this.city,
    this.state,
    this.country,
    this.status,
  });

  factory TrialLocation.fromJson(Map<String, dynamic> json) => TrialLocation(
        facility: json['facility'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        country: json['country'] as String?,
        status: json['status'] as String?,
      );

  String get cityCountry => [city, state, country]
      .where((s) => s != null && s.isNotEmpty)
      .join(', ');
}

class TrialsResult {
  final List<ClinicalTrial> trials;
  final int totalCount;
  final String? nextPageToken;

  const TrialsResult({
    required this.trials,
    required this.totalCount,
    this.nextPageToken,
  });
}
