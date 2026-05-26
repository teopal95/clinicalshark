import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class NarrativeResult {
  final List<String> conditions;
  final String searchQuery;

  const NarrativeResult({required this.conditions, required this.searchQuery});
}

// ── Live AI version (requires Gemini API key) ─────────────────────────────────

class NarrativeService {
  final String _apiKey;

  NarrativeService(this._apiKey);

  Future<NarrativeResult> analyze(String narrative) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt = '''You are a medical language translator helping a patient find relevant clinical trials on ClinicalTrials.gov.

The patient wrote this about their health in plain language:
"$narrative"

Your task:
1. Extract medical conditions and diagnoses mentioned (max 10 items, use plain English labels)
2. Generate a concise search query using proper medical terminology for ClinicalTrials.gov (max 120 characters)

Rules:
- Translate lay terms to accepted medical terms in the searchQuery (e.g. "blood sugar problems" → "type 2 diabetes", "bad knees" → "osteoarthritis knee")
- List the most relevant condition first
- If no clear conditions are found, make a reasonable inference from context
- Conditions list should use human-readable labels (e.g. "Type 2 Diabetes", not "DM2")

Respond ONLY with valid JSON in this exact format:
{
  "conditions": ["Condition 1", "Condition 2"],
  "searchQuery": "medical search terms for ClinicalTrials.gov"
}''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    final cleaned = text.trim().replaceAll(RegExp(r'^```json\s*|\s*```$'), '');
    final decoded = jsonDecode(cleaned) as Map<String, dynamic>;

    return NarrativeResult(
      conditions: (decoded['conditions'] as List<dynamic>)
          .map((c) => c.toString())
          .toList(),
      searchQuery: decoded['searchQuery'] as String,
    );
  }
}

// ── Simulated version — no API key needed, works fully offline ────────────────
//
// Maps lay-language phrases to (display label, search term) pairs.
// Multi-word phrases are checked first to avoid partial matches.

class MockNarrativeService {
  // Each entry: pattern → (display label, medical search term)
  static const _phrases = <(String, String, String)>[
    // Multi-word first
    ('high blood pressure', 'Hypertension', 'hypertension'),
    ('blood pressure', 'Hypertension', 'hypertension'),
    ('blood sugar', 'Diabetes', 'diabetes'),
    ('type 2 diabetes', 'Type 2 Diabetes', 'type 2 diabetes'),
    ('type 1 diabetes', 'Type 1 Diabetes', 'type 1 diabetes'),
    ('breast cancer', 'Breast Cancer', 'breast cancer'),
    ('lung cancer', 'Lung Cancer', 'lung cancer'),
    ('skin cancer', 'Skin Cancer', 'skin cancer melanoma'),
    ('colon cancer', 'Colorectal Cancer', 'colorectal cancer'),
    ('prostate cancer', 'Prostate Cancer', 'prostate cancer'),
    ('multiple sclerosis', 'Multiple Sclerosis', 'multiple sclerosis'),
    ('rheumatoid arthritis', 'Rheumatoid Arthritis', 'rheumatoid arthritis'),
    ('joint pain', 'Arthritis', 'arthritis joint pain'),
    ('back pain', 'Chronic Back Pain', 'chronic back pain'),
    ('atrial fibrillation', 'Atrial Fibrillation', 'atrial fibrillation'),
    ('heart failure', 'Heart Failure', 'heart failure'),
    ('heart disease', 'Cardiovascular Disease', 'cardiovascular disease'),
    ('kidney disease', 'Chronic Kidney Disease', 'chronic kidney disease'),
    ('liver disease', 'Liver Disease', 'liver disease'),
    ('mental health', 'Mental Health', 'mental health'),
    ('bipolar disorder', 'Bipolar Disorder', 'bipolar disorder'),
    ('inflammatory bowel', 'Inflammatory Bowel Disease', 'inflammatory bowel disease'),
    ('crohn', "Crohn's Disease", "crohn's disease"),
    ('ulcerative colitis', 'Ulcerative Colitis', 'ulcerative colitis'),
    ('thyroid', 'Thyroid Disease', 'thyroid disease'),
    // Single-word
    ('diabetic', 'Type 2 Diabetes', 'type 2 diabetes'),
    ('diabetes', 'Diabetes', 'diabetes'),
    ('metformin', 'Type 2 Diabetes', 'type 2 diabetes'),
    ('insulin', 'Diabetes', 'diabetes insulin'),
    ('hba1c', 'Type 2 Diabetes', 'type 2 diabetes'),
    ('hypertension', 'Hypertension', 'hypertension'),
    ('cholesterol', 'Hypercholesterolemia', 'hypercholesterolemia cholesterol'),
    ('statin', 'Hypercholesterolemia', 'hypercholesterolemia'),
    ('cardiac', 'Cardiovascular Disease', 'cardiovascular disease'),
    ('cancer', 'Cancer', 'cancer'),
    ('tumor', 'Cancer', 'cancer tumor'),
    ('chemotherapy', 'Cancer', 'cancer chemotherapy'),
    ('chemo', 'Cancer', 'cancer chemotherapy'),
    ('oncology', 'Cancer', 'cancer oncology'),
    ('kidney', 'Chronic Kidney Disease', 'chronic kidney disease'),
    ('renal', 'Chronic Kidney Disease', 'renal disease'),
    ('hepatitis', 'Hepatitis', 'hepatitis'),
    ('liver', 'Liver Disease', 'liver disease'),
    ('depression', 'Depression', 'depression'),
    ('anxiety', 'Anxiety Disorder', 'anxiety disorder'),
    ('bipolar', 'Bipolar Disorder', 'bipolar disorder'),
    ('schizophrenia', 'Schizophrenia', 'schizophrenia'),
    ('adhd', 'ADHD', 'attention deficit hyperactivity disorder'),
    ('autism', 'Autism Spectrum Disorder', 'autism spectrum disorder'),
    ("alzheimer", "Alzheimer's Disease", "alzheimer's disease"),
    ("parkinson", "Parkinson's Disease", "parkinson's disease"),
    ('epilepsy', 'Epilepsy', 'epilepsy'),
    ('seizure', 'Epilepsy', 'epilepsy seizure'),
    ('stroke', 'Stroke', 'stroke cerebrovascular'),
    ('migraine', 'Migraine', 'migraine headache'),
    ('asthma', 'Asthma', 'asthma'),
    ('copd', 'COPD', 'chronic obstructive pulmonary disease'),
    ('emphysema', 'COPD', 'chronic obstructive pulmonary disease'),
    ('arthritis', 'Arthritis', 'arthritis'),
    ('osteoporosis', 'Osteoporosis', 'osteoporosis'),
    ('knee', 'Osteoarthritis', 'osteoarthritis knee'),
    ('fibromyalgia', 'Fibromyalgia', 'fibromyalgia'),
    ('obesity', 'Obesity', 'obesity'),
    ('overweight', 'Obesity', 'obesity overweight'),
    ('hiv', 'HIV/AIDS', 'hiv aids'),
    ('aids', 'HIV/AIDS', 'hiv aids'),
    ('covid', 'COVID-19', 'covid-19 coronavirus'),
    ('coronavirus', 'COVID-19', 'covid-19'),
    ('lupus', 'Lupus', 'lupus systemic lupus erythematosus'),
    ('psoriasis', 'Psoriasis', 'psoriasis'),
    ('eczema', 'Eczema', 'atopic dermatitis eczema'),
    ('colitis', 'Ulcerative Colitis', 'ulcerative colitis'),
    ('prostate', 'Prostate Disease', 'prostate'),
    ('afib', 'Atrial Fibrillation', 'atrial fibrillation'),
  ];

  Future<NarrativeResult> analyze(String narrative) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 900));

    final lower = narrative.toLowerCase();
    final seenLabels = <String>{};
    final conditions = <String>[];
    final queryTerms = <String>[];

    for (final (phrase, label, term) in _phrases) {
      if (lower.contains(phrase) && seenLabels.add(label)) {
        conditions.add(label);
        queryTerms.add(term);
        if (conditions.length >= 6) break;
      }
    }

    if (conditions.isEmpty) {
      // Fallback: use first few meaningful words as-is
      final words = narrative
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 4)
          .take(3)
          .join(' ');
      return NarrativeResult(
        conditions: [],
        searchQuery: words.isNotEmpty ? words : narrative.substring(0, narrative.length.clamp(0, 60)),
      );
    }

    // Build search query: deduplicated terms, capped at 120 chars
    var query = queryTerms.toSet().join(' ');
    if (query.length > 120) query = query.substring(0, 120).trimRight();

    return NarrativeResult(conditions: conditions, searchQuery: query);
  }
}
