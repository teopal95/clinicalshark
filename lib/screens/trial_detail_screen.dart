import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clinical_trial.dart';
import '../services/trials_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_fab.dart';

class TrialDetailScreen extends StatefulWidget {
  final String nctId;
  const TrialDetailScreen({super.key, required this.nctId});

  @override
  State<TrialDetailScreen> createState() => _TrialDetailScreenState();
}

class _TrialDetailScreenState extends State<TrialDetailScreen> {
  ClinicalTrial? _trial;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await TrialsService().getById(widget.nctId);
      if (mounted) setState(() { _trial = t; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) return _buildError();
    return _buildDetail(_trial!);
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Could not load trial',
                style: GoogleFonts.inter(fontSize: 17)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _load();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(ClinicalTrial t) {
    final statusColor = AppTheme.getStatusColor(t.overallStatus);

    return Scaffold(
      floatingActionButton: ChatFab(trial: t),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy NCT ID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: t.nctId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('NCT ID copied to clipboard'),
                        duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, Color(0xFF2471A3)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 90, 20, 16),
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppTheme.getStatusLabel(t.overallStatus),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (t.phases.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.phases.join(' / '),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.briefTitle,
                    style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.nctId,
                    style: GoogleFonts.robotoMono(
                        fontSize: 12, color: AppTheme.secondaryColor),
                  ),
                  const SizedBox(height: 20),
                  _buildFactCard(t),
                  const SizedBox(height: 24),
                  if (t.briefSummary != null) ...[
                    _SectionTitle('Study Summary', Icons.description_outlined),
                    const SizedBox(height: 10),
                    Text(t.briefSummary!,
                        style: GoogleFonts.inter(
                            fontSize: 14, height: 1.6, color: Colors.black87)),
                    const SizedBox(height: 24),
                  ],
                  _SectionTitle('Who Can Join', Icons.people_alt_outlined),
                  const SizedBox(height: 12),
                  _buildEligibility(t),
                  const SizedBox(height: 24),
                  if (t.locations.isNotEmpty) ...[
                    _SectionTitle(
                      'Locations',
                      Icons.location_on_outlined,
                      sub: '${t.locations.length} site${t.locations.length > 1 ? 's' : ''}',
                    ),
                    const SizedBox(height: 12),
                    _buildLocations(t),
                    const SizedBox(height: 24),
                  ],
                  if (t.eligibilityCriteria != null) ...[
                    _SectionTitle(
                        'Full Eligibility Criteria', Icons.checklist_rounded),
                    const SizedBox(height: 10),
                    _ExpandableText(text: t.eligibilityCriteria!),
                    const SizedBox(height: 24),
                  ],
                  _buildDisclaimer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactCard(ClinicalTrial t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Fact(
                    'Phase',
                    t.phases.isNotEmpty ? t.phases.join(', ') : 'N/A',
                    Icons.science_outlined),
              ),
              Expanded(
                child: _Fact(
                    'Study Type',
                    t.studyType.replaceAll('_', ' '),
                    Icons.biotech_outlined),
              ),
            ],
          ),
          if (t.enrollmentCount != null || t.sponsorName != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                if (t.enrollmentCount != null)
                  Expanded(
                    child: _Fact(
                        'Enrollment',
                        '${t.enrollmentCount} participants',
                        Icons.people_outlined),
                  ),
                if (t.sponsorName != null)
                  Expanded(
                    child: _Fact(
                        'Sponsor', t.sponsorName!, Icons.business_outlined),
                  ),
              ],
            ),
          ],
          if (t.startDate != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Fact(
                      'Start Date', t.startDate!, Icons.calendar_today_outlined),
                ),
                if (t.completionDate != null)
                  Expanded(
                    child: _Fact('Est. Completion', t.completionDate!,
                        Icons.event_outlined),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEligibility(ClinicalTrial t) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _EligCard(Icons.wc, 'Sex', _formatSex(t.sex)),
        _EligCard(Icons.child_care_outlined, 'Min Age', t.minimumAge ?? 'Any'),
        _EligCard(Icons.elderly_outlined, 'Max Age', t.maximumAge ?? 'Any'),
      ],
    );
  }

  Widget _buildLocations(ClinicalTrial t) {
    final shown = t.locations.take(6).toList();
    final extra = t.locations.length - shown.length;

    return Column(
      children: [
        ...shown.map((loc) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 16, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (loc.facility != null)
                          Text(loc.facility!,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        if (loc.cityCountry.isNotEmpty)
                          Text(loc.cityCountry,
                              style: GoogleFonts.inter(
                                  color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  if (loc.status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(loc.status!)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppTheme.getStatusLabel(loc.status!),
                        style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.getStatusColor(loc.status!),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            )),
        if (extra > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ $extra more location${extra > 1 ? 's' : ''}',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBDD3F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppTheme.secondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data sourced from ClinicalTrials.gov. Always consult a qualified healthcare professional before participating in any clinical trial.',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.blueGrey[700],
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSex(String? sex) {
    switch (sex?.toUpperCase()) {
      case 'ALL':
        return 'All';
      case 'MALE':
        return 'Male only';
      case 'FEMALE':
        return 'Female only';
      default:
        return sex ?? 'All';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? sub;
  const _SectionTitle(this.title, this.icon, {this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor)),
        if (sub != null) ...[
          const SizedBox(width: 6),
          Text(sub!,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Fact(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _EligCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _EligCard(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.secondaryColor),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
          Text(value,
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const previewLen = 600;
    final isLong = widget.text.length > previewLen;
    final display = _expanded || !isLong
        ? widget.text
        : '${widget.text.substring(0, previewLen)}…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(display,
              style:
                  GoogleFonts.inter(fontSize: 13, height: 1.65, color: Colors.black87)),
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show less' : 'Show full criteria'),
          ),
        ],
      ],
    );
  }
}
