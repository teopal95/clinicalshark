# ClinicalShark

A Flutter app that makes discovering clinical trials easy for everyone — no medical degree required.

ClinicalShark connects to the live [ClinicalTrials.gov API v2](https://clinicaltrials.gov/data-api/api) and presents trials in a clean, readable UI with plain-language labels and smart filters.

## Features

- **Search by condition** — type any condition or pick from common quick-select cards on the home screen
- **Filter results** — narrow by trial status (Recruiting, Completed, etc.) and phase (Phase 1–4)
- **Infinite scroll** — results load progressively as you browse
- **Trial detail view** — full study info including eligibility criteria, locations, and contact details

## Screenshots

> Coming soon

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
