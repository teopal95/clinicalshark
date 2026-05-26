import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/trials_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_fab.dart';
import '../widgets/trial_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? status;
  final String? phase;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.status,
    this.phase,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;
  String? _status;
  String? _phase;

  static const _statuses = [
    ('All Statuses', null),
    ('Recruiting', 'RECRUITING'),
    ('Not Yet Recruiting', 'NOT_YET_RECRUITING'),
    ('Active (not recruiting)', 'ACTIVE_NOT_RECRUITING'),
    ('Completed', 'COMPLETED'),
    ('Terminated', 'TERMINATED'),
  ];

  static const _phases = [
    ('All Phases', null),
    ('Phase 1', 'PHASE1'),
    ('Phase 2', 'PHASE2'),
    ('Phase 3', 'PHASE3'),
    ('Phase 4', 'PHASE4'),
    ('N/A', 'NA'),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.query);
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _status = widget.status;
    _phase = widget.phase;
    WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch());
  }

  void _doSearch() {
    context.read<TrialsProvider>().search(
          query: _searchCtrl.text.trim(),
          status: _status,
          phase: _phase,
        );
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      context.read<TrialsProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ChatFab(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('ClinicalShark'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildSearchBar(),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search trials…',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  prefixIcon:
                      const Icon(Icons.search, size: 18, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _doSearch(),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _doSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text('Go', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _Dropdown<String?>(
              value: _status,
              items: _statuses,
              onChanged: (v) {
                setState(() => _status = v);
                _doSearch();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Dropdown<String?>(
              value: _phase,
              items: _phases,
              onChanged: (v) {
                setState(() => _phase = v);
                _doSearch();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Consumer<TrialsProvider>(
      builder: (context, p, _) {
        if (p.state == TrialsState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (p.state == TrialsState.error) {
          return _ErrorState(onRetry: _doSearch);
        }

        if (p.state == TrialsState.loaded && p.trials.isEmpty) {
          return _EmptyState(query: _searchCtrl.text);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.totalCount > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${_formatCount(p.totalCount)} results',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: p.trials.length + (p.isLoadingMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= p.trials.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final trial = p.trials[i];
                  return TrialCard(
                    trial: trial,
                    onTap: () => context.push('/trial/${trial.nctId}'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<(String, T)> items;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e.$2,
                    child: Text(e.$1,
                        style: GoogleFonts.inter(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null || null is T) onChanged(v as T);
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Could not load results',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('Check your connection and try again.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No trials found for "$query"',
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Try different keywords or remove filters.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
