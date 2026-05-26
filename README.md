# ClinicalShark

A Flutter app that makes discovering clinical trials easy for everyone — no medical degree required.

ClinicalShark connects to the live [ClinicalTrials.gov API v2](https://clinicaltrials.gov/data-api/api) and presents trials in a clean, readable UI with plain-language labels and smart filters.

## Features

- **Search by condition** — type any condition or pick from common quick-select cards on the home screen
- **Filter results** — narrow by trial status (Recruiting, Completed, etc.) and phase (Phase 1–4)
- **Infinite scroll** — results load progressively as you browse
- **Trial detail view** — full study info including eligibility criteria, locations, and contact details
- **Plain-language health profile** — describe your medical history in your own words; the app translates everyday language into clinical search terms and surfaces a personalised "Trials for you" shortcut on the home screen

## Screenshots

> Coming soon

## How the health profile works

During profile setup, users describe their medical history in plain language — no forms, no dropdowns, no medical jargon required.

> *"I'm 52 with type 2 diabetes and high blood pressure. I've been on metformin for 3 years and also have mild kidney disease."*

The app recognises conditions and medications in the text, maps them to accepted clinical terminology, and builds a search query optimised for ClinicalTrials.gov. Matched conditions are shown as editable chips so the user stays in control. Once saved, a **Trials matched to your profile** shortcut appears on the home screen for one-tap personalised search.

The language-matching engine runs fully on-device with no external API required, making it suitable for offline use and demo environments.

## Tech Stack

| Layer | Library |
|---|---|
| UI | Flutter (Material 3) |
| Routing | go_router |
| State | provider |
| Fonts | google_fonts |
| HTTP | http |

## Getting Started

### Prerequisites

- Flutter SDK `>=3.7.2`
- Dart SDK `>=3.7.2`

### Run locally

```bash
git clone https://github.com/teopal95/clinicalshark.git
cd clinicalshark
flutter pub get
flutter run
```

Supports **web**, **Android**, and **iOS** targets.

## Data Source

All trial data is fetched in real time from the public [ClinicalTrials.gov API v2](https://clinicaltrials.gov/data-api/api). No API key required.

## License

MIT
