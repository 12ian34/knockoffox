# Roadmap

Knockoffox should stay useful without any backend. Bundled brand lists and
local heuristics are the reliability layer; APIs should only add freshness,
reporting, and community curation.

## Near Term

- Publish and QA the Firefox extension through AMO.
- Manually test live Amazon search pages, product pages, toolbar panel behavior,
  options saving, and report actions in Firefox.
- Add Firefox-specific store assets, screenshots, and install docs.
- Keep expanding `tests/fixtures.js` with real false positives and false
  negatives before changing classifier behavior.

## Make It Better Than Upstream

- Add a review/onboarding mode that labels suspicious listings before hiding
  anything, so users can build trust in the classifier.
- Show clearer "why this was filtered" details: matched list, score, and
  heuristic reasons.
- Add better one-click controls: trust brand, block brand, report brand,
  dismiss item for this session, and undo recent actions.
- Improve category-aware generic-word handling so product descriptors are less
  likely to be misread as brands.
- Consider Firefox-specific improvements such as Android support or a local
  filtered-brand history page.

## Backend And Data Independence

- Snapshot the current upstream API data while it is available:
  `GET https://api.knockoff.shopping/brands` and
  `GET https://api.knockoff.shopping/flagged`.
- Add a script that fetches those lists, validates sane sizes/content, and
  regenerates bundled data files.
- Eventually deploy a fork-owned backend with the same small contract:
  `GET /brands`, `GET /flagged`, and `POST /report`.
- Prefer Cloudflare Workers + D1 because `report-worker/` already contains an
  upstream implementation to adapt.
- Do not blindly trust user reports. Reports should enter a moderation/review
  queue before becoming bundled or remotely served brand decisions.
- If no fork-owned reporting endpoint is configured, fall back to GitHub issues
  rather than posting fork user reports to the upstream API.

## Guardrails

- Do not make shopping-page classification depend on network availability.
- Avoid automatic seller-page scraping in the default path; it is slower, more
  fragile, and likely to trigger Amazon rate limits.
- Treat false positives as worse than false negatives. Real brands getting
  hidden damages user trust more than junk slipping through.
