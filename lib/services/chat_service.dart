import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/clinical_trial.dart';

class ChatService {
  late final ChatSession _chat;

  ChatService(String apiKey, {ClinicalTrial? trial}) {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt(trial)),
    );
    _chat = model.startChat();
  }

  Future<String> send(String userMessage) async {
    final response = await _chat.sendMessage(Content.text(userMessage));
    return response.text?.trim() ?? 'Sorry, I could not generate a response.';
  }

  String _systemPrompt(ClinicalTrial? trial) {
    const base = '''You are a friendly and knowledgeable clinical trials assistant for ClinicalShark, a patient-facing app that makes clinical trial information accessible.

Your role is to help patients, caregivers, and researchers understand clinical trials clearly and without intimidating medical jargon.

You can explain:
- What clinical trials are and how they work
- Phase 1 through 4: what each phase tests and what it means for participants
- Eligibility criteria in plain language (inclusion/exclusion)
- Study statuses: Recruiting, Active Not Recruiting, Completed, Terminated, etc.
- Trial terminology: randomization, placebo, double-blind, endpoint, IRB, informed consent, etc.
- What to expect as a participant (visits, procedures, time commitment)
- Questions to bring to a doctor when considering a trial
- Risks and benefits of trial participation in general

Communication style:
- Always use plain, compassionate language
- Keep answers focused and concise — don't overwhelm with walls of text
- Use bullet points when listing multiple items
- When asked about personal medical decisions, remind users to consult their healthcare provider
- If you are unsure of something, say so honestly rather than guessing''';

    if (trial == null) return base;

    return '''$base

---
The user is currently viewing the following specific clinical trial. Use this information to answer questions about this specific study:

${_trialContext(trial)}
---

When answering about this trial, refer to the specific details above. Help the user understand whether they might be eligible, what the study involves, where it's conducted, and anything else they ask about.''';
  }

  String _trialContext(ClinicalTrial t) {
    final b = StringBuffer();
    b.writeln('NCT ID: ${t.nctId}');
    b.writeln('Title: ${t.briefTitle}');
    if (t.officialTitle != null && t.officialTitle != t.briefTitle) {
      b.writeln('Official Title: ${t.officialTitle}');
    }
    b.writeln('Status: ${t.overallStatus.replaceAll('_', ' ')}');
    b.writeln('Phase: ${t.phases.isNotEmpty ? t.phases.join(', ') : 'Not specified'}');
    b.writeln('Study Type: ${t.studyType}');
    if (t.sponsorName != null) b.writeln('Lead Sponsor: ${t.sponsorName}');
    if (t.conditions.isNotEmpty) b.writeln('Conditions: ${t.conditions.join(', ')}');
    if (t.keywords.isNotEmpty) b.writeln('Keywords: ${t.keywords.take(10).join(', ')}');
    b.writeln('Sex Eligible: ${t.sex ?? 'All'}');
    if (t.minimumAge != null) b.writeln('Minimum Age: ${t.minimumAge}');
    if (t.maximumAge != null) b.writeln('Maximum Age: ${t.maximumAge}');
    if (t.enrollmentCount != null) {
      b.writeln('Target Enrollment: ${t.enrollmentCount} participants');
    }
    if (t.startDate != null) b.writeln('Start Date: ${t.startDate}');
    if (t.completionDate != null) {
      b.writeln('Estimated Completion: ${t.completionDate}');
    }

    if (t.briefSummary != null) {
      b.writeln('\nSTUDY SUMMARY:\n${t.briefSummary}');
    }

    if (t.eligibilityCriteria != null) {
      b.writeln('\nELIGIBILITY CRITERIA:\n${t.eligibilityCriteria}');
    }

    if (t.locations.isNotEmpty) {
      b.writeln('\nSTUDY LOCATIONS:');
      for (final loc in t.locations.take(15)) {
        final parts = [loc.facility, loc.city, loc.state, loc.country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        b.writeln('- $parts (${loc.status?.replaceAll('_', ' ') ?? 'status unknown'})');
      }
      if (t.locations.length > 15) {
        b.writeln('... and ${t.locations.length - 15} more locations');
      }
    }

    return b.toString();
  }
}
