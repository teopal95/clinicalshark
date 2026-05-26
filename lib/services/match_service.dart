import '../models/clinical_trial.dart';
import '../models/user_profile.dart';
import 'trials_service.dart';

class TrialMatch {
  final ClinicalTrial trial;
  final List<String> matchReasons;

  const TrialMatch({required this.trial, required this.matchReasons});
}

class MatchService {
  final _trialsService = TrialsService();

  Future<List<TrialMatch>> findMatches(UserProfile profile) async {
    if (profile.conditions.isEmpty) return [];

    final conditions = profile.conditions.take(3).toList();
    final seen = <String>{};
    final allTrials = <ClinicalTrial>[];

    for (final condition in conditions) {
      try {
        final result = await _trialsService.search(
          query: condition,
          status: 'RECRUITING',
          pageSize: 20,
        );
        for (final trial in result.trials) {
          if (seen.add(trial.nctId)) {
            allTrials.add(trial);
          }
        }
      } catch (_) {
        // skip failed condition fetch
      }
    }

    final matches = <TrialMatch>[];
    final userAge = profile.ageYears;

    for (final trial in allTrials) {
      if (!_sexEligible(trial.sex, profile.sex)) continue;
      if (!_ageEligible(trial.minimumAge, trial.maximumAge, userAge)) continue;

      final reasons = _buildReasons(trial, profile, userAge);
      matches.add(TrialMatch(trial: trial, matchReasons: reasons));
    }

    return matches;
  }

  bool _sexEligible(String? trialSex, String userSex) {
    if (trialSex == null || trialSex == 'ALL') return true;
    if (userSex == 'ALL') return true;
    return trialSex.toUpperCase() == userSex.toUpperCase();
  }

  bool _ageEligible(String? minAgeStr, String? maxAgeStr, int? userAge) {
    if (userAge == null) return true;
    final minAge = _parseAge(minAgeStr);
    final maxAge = _parseAge(maxAgeStr);
    if (minAge != null && userAge < minAge) return false;
    if (maxAge != null && userAge > maxAge) return false;
    return true;
  }

  int? _parseAge(String? ageStr) {
    if (ageStr == null || ageStr.isEmpty) return null;
    final match = RegExp(r'(\d+)').firstMatch(ageStr);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  List<String> _buildReasons(
      ClinicalTrial trial, UserProfile profile, int? userAge) {
    final reasons = <String>[];

    final matchedConditions = profile.conditions
        .where((c) => trial.conditions
            .any((tc) => tc.toLowerCase().contains(c.toLowerCase()) ||
                c.toLowerCase().contains(tc.toLowerCase())))
        .toList();
    if (matchedConditions.isNotEmpty) {
      reasons.add('Matches: ${matchedConditions.first}');
    }

    final trialSex = trial.sex?.toUpperCase();
    if (trialSex == null || trialSex == 'ALL') {
      reasons.add('Open to all sexes');
    } else {
      reasons.add('${_capitalize(trialSex)} eligible');
    }

    if (userAge != null) {
      final minAge = _parseAge(trial.minimumAge);
      final maxAge = _parseAge(trial.maximumAge);
      if (minAge != null && maxAge != null) {
        reasons.add('Age $minAge–$maxAge eligible');
      } else if (minAge != null) {
        reasons.add('Age $minAge+ eligible');
      } else {
        reasons.add('Age eligible');
      }
    }

    return reasons;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }
}
