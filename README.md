# Kyros Red F&B Cost Calculator MVP

A Next.js prototype that showcases a GitHub-backed food & beverage costing workflow. The MVP loads fixture data, lets you model menu ingredient costs, and persists menu JSON files through the GitHub REST API.

## Features

- ✅ Reactive ingredient cost table with summary metrics
- ✅ GitHub storage helpers for reading/writing repo content
- ✅ Exporters for PDF (Kyros Red styling) and Excel workbooks
- ✅ Sample chart visualising ingredient pricing trends
- ✅ REST API route to persist menu drafts back to `menus/`

## Getting Started

```bash
npm install
npm run dev
```

Set the following environment variables for GitHub access:

- `GITHUB_TOKEN`
- `GITHUB_OWNER`
- `GITHUB_REPO`

Run the app and open http://localhost:3000.

## Repository Data Shape

This repository includes sample JSON, CSV, and Markdown files that illustrate how menu, supplier, SOP, and benchmarking data will be versioned in GitHub.
