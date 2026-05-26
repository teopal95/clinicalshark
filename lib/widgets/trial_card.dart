import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clinical_trial.dart';
import '../theme/app_theme.dart';

class TrialCard extends StatelessWidget {
  final ClinicalTrial trial;
  final VoidCallback onTap;

  const TrialCard({super.key, required this.trial, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      trial.briefTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(status: trial.overallStatus),
                ],
              ),
              if (trial.briefSummary != null) ...[
                const SizedBox(height: 8),
                Text(
                  trial.briefSummary!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (trial.phases.isNotEmpty)
                    _Chip(
                      icon: Icons.science_outlined,
                      label: trial.phases.join(', '),
                      color: AppTheme.secondaryColor,
                    ),
                  if (trial.conditions.isNotEmpty)
                    _Chip(
                      icon: Icons.medical_services_outlined,
                      label: trial.conditions.first,
                      color: const Color(0xFF8E44AD),
                    ),
                  if (trial.locations.isNotEmpty)
                    _Chip(
                      icon: Icons.location_on_outlined,
                      label:
                          '${trial.locations.length} site${trial.locations.length > 1 ? 's' : ''}',
                      color: Colors.grey.shade600,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (trial.sponsorName != null) ...[
                    Icon(Icons.business_outlined,
                        size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trial.sponsorName!,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Text(
                    trial.nctId,
                    style: GoogleFonts.robotoMono(
                        fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        AppTheme.getStatusLabel(status),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
