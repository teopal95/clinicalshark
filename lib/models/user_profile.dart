class UserProfile {
  final String uid;
  final String name;
  final String email;
  final DateTime? dateOfBirth;
  final String sex;
  final List<String> conditions;
  final String? city;
  final String? country;
  final bool profileComplete;
  final String? healthNarrative;
  final String? narrativeSearchQuery;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.dateOfBirth,
    this.sex = 'ALL',
    this.conditions = const [],
    this.city,
    this.country,
    this.profileComplete = false,
    this.healthNarrative,
    this.narrativeSearchQuery,
  });

  int? get ageYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'sex': sex,
        'conditions': conditions,
        'city': city,
        'country': country,
        'profileComplete': profileComplete,
        'healthNarrative': healthNarrative,
        'narrativeSearchQuery': narrativeSearchQuery,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.parse(json['dateOfBirth'] as String)
            : null,
        sex: json['sex'] as String? ?? 'ALL',
        conditions: (json['conditions'] as List<dynamic>? ?? [])
            .map((c) => c.toString())
            .toList(),
        city: json['city'] as String?,
        country: json['country'] as String?,
        profileComplete: json['profileComplete'] as bool? ?? false,
        healthNarrative: json['healthNarrative'] as String?,
        narrativeSearchQuery: json['narrativeSearchQuery'] as String?,
      );

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? sex,
    List<String>? conditions,
    String? city,
    bool clearCity = false,
    String? country,
    bool clearCountry = false,
    bool? profileComplete,
    String? healthNarrative,
    bool clearHealthNarrative = false,
    String? narrativeSearchQuery,
    bool clearNarrativeSearchQuery = false,
  }) =>
      UserProfile(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        dateOfBirth:
            clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
        sex: sex ?? this.sex,
        conditions: conditions ?? this.conditions,
        city: clearCity ? null : (city ?? this.city),
        country: clearCountry ? null : (country ?? this.country),
        profileComplete: profileComplete ?? this.profileComplete,
        healthNarrative: clearHealthNarrative ? null : (healthNarrative ?? this.healthNarrative),
        narrativeSearchQuery: clearNarrativeSearchQuery ? null : (narrativeSearchQuery ?? this.narrativeSearchQuery),
      );
}
