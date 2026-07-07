# Release notes

Canonical "what's new" copy for each release — the text that goes in the Chrome
Web Store "Release notes" field, the AMO version notes, and the App Store
Connect "What's New" field. Newest first. Move items out of **Unreleased** into a
version heading when you cut a release.

## Unreleased

## 0.2.0

- New: works on every Amazon marketplace (Germany, France, Italy, Spain,
  Japan, India, Mexico, Brazil, and more) with locale-aware brand detection.
  Previously only .com, .ca, .co.uk, and .com.au.
- New: optional toggle to hide Amazon "Sponsored" listings, in the Knockoff
  control panel. Off by default; leaves organic results (and Amazon's own
  "Featured from Amazon brands" tiles) untouched.
- Changed: filtered listings are now dimmed by default instead of hidden, so
  you can see what Knockoff caught. Prefer them gone? Switch the action to
  Hide in the control panel.

## 0.1.0

- Initial release. Filters trademark-squat pseudo-brands out of Amazon search
  results with hide / dim / label actions, three filter levels (Relaxed,
  Standard, Strict), personal allow/block lists, and one-click misclassification
  reporting. Runs locally; the only network request is a daily brand-list
  refresh. Works on amazon.com, .ca, .co.uk, and .com.au.
