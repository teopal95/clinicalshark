import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clinical_trial.dart';

class TrialsService {
  static const _base = 'https://clinicaltrials.gov/api/v2';

  Future<TrialsResult> search({
    String? query,
    String? status,
    String? phase,
    String? pageToken,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'format': 'json',
      'pageSize': pageSize.toString(),
    };
    if (query != null && query.isNotEmpty) params['query.term'] = query;
    if (status != null && status.isNotEmpty) {
      params['filter.overallStatus'] = status;
    }
    if (phase != null && phase.isNotEmpty) params['filter.phase'] = phase;
    if (pageToken != null) params['pageToken'] = pageToken;

    final uri =
        Uri.parse('$_base/studies').replace(queryParameters: params);
    final response =
        await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return TrialsResult(
      trials: (data['studies'] as List<dynamic>? ?? [])
          .map((s) => ClinicalTrial.fromJson(s as Map<String, dynamic>))
          .toList(),
      totalCount: data['totalCount'] as int? ?? 0,
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  Future<ClinicalTrial> getById(String nctId) async {
    final uri = Uri.parse('$_base/studies/$nctId')
        .replace(queryParameters: {'format': 'json'});
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Trial not found');
    return ClinicalTrial.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }
}
