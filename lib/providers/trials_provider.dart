import 'package:flutter/material.dart';
import '../models/clinical_trial.dart';
import '../services/trials_service.dart';

enum TrialsState { idle, loading, loaded, error }

class TrialsProvider extends ChangeNotifier {
  final _service = TrialsService();

  List<ClinicalTrial> _trials = [];
  TrialsState _state = TrialsState.idle;
  String? _error;
  int _totalCount = 0;
  String? _nextPageToken;
  bool _isLoadingMore = false;

  String _lastQuery = '';
  String? _lastStatus;
  String? _lastPhase;

  List<ClinicalTrial> get trials => _trials;
  TrialsState get state => _state;
  String? get error => _error;
  int get totalCount => _totalCount;
  bool get hasMore => _nextPageToken != null;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> search({
    required String query,
    String? status,
    String? phase,
  }) async {
    _lastQuery = query;
    _lastStatus = status;
    _lastPhase = phase;
    _trials = [];
    _nextPageToken = null;
    _error = null;
    _state = TrialsState.loading;
    notifyListeners();

    try {
      final result = await _service.search(
        query: query,
        status: status,
        phase: phase,
      );
      _trials = result.trials;
      _totalCount = result.totalCount;
      _nextPageToken = result.nextPageToken;
      _state = TrialsState.loaded;
    } catch (e) {
      _state = TrialsState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _nextPageToken == null) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.search(
        query: _lastQuery,
        status: _lastStatus,
        phase: _lastPhase,
        pageToken: _nextPageToken,
      );
      _trials = [..._trials, ...result.trials];
      _nextPageToken = result.nextPageToken;
    } catch (_) {
      // silently ignore pagination errors
    }
    _isLoadingMore = false;
    notifyListeners();
  }
}
