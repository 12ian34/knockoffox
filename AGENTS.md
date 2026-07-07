# AGENTS.md

## Project

Knockoffox is a Firefox-focused port of `Shpigford/knockoff`, a plain MV3
WebExtension that filters pseudo-brand Amazon listings. There is no build
step, package manager, framework, or module system; the repo root is loadable
as a temporary Firefox add-on by selecting `manifest.json` from
`about:debugging#/runtime/this-firefox`.

## Commands

- `node tests/run.js` runs the detector and product-page brand extraction tests.
- `npx --yes web-ext lint --source-dir <dir>` validates a Firefox extension
  directory. For AMO-style validation, lint a directory containing only
  `manifest.json`, `src`, `data`, `options`, and `icons`.
- `scripts/release-firefox.sh --lint-only` performs the release-script lint path;
  note that it creates and cleans temporary build directories.

## Extension Notes

- Prefer Firefox's promise-based `browser.*` API when available. The source uses
  a local `runtimeApi` fallback so copied Chrome-style code still works.
- Firefox ignores `background.service_worker`; `manifest.json` also includes
  `background.scripts` for Firefox. The Firefox release script strips the
  Chrome-only service worker key from the AMO build directory.
- Content script load order in `manifest.json` matters: data files, then
  `src/detector.js`, `src/pdp-brand.js`, and finally `src/content.js`.
- The Safari wrapper under `safari/` is inherited upstream material and is not
  automatically kept in sync for Firefox-only changes.
