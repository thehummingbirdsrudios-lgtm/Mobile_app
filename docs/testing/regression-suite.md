# Regression suite

**Run before every merge (CI):** app format, analyze, boundaries, `flutter
test`, legal sync, web and APK builds; `tool/db_test.sh --scale`; gitleaks.

## Bugs found and their regression tests
| ID | Bug | Root cause | Regression test |
|---|---|---|---|
| R-001 | Catalogue page took 61 ms at scale | `SET search_path` blocked SQL-function inlining | `scale_perf_test.dart` latency and plan checks |
| R-002 | Android build failed in CI | Package `in.hummingbird.vepari`: `in` is a Java keyword | CI `flutter build apk --debug` |
| R-003 | Status chip text failed AA contrast (4.4:1) | Success colour too light for 12 px text | Contrast table in `ui-principles.md` (manual) |
| R-004 | Legal screen would show raw Markdown | Plain `Text` of `.md` | `app/test/features/legal_text_test.dart` |
| R-005 | Tablet Home stretched edge to edge | No max content width | Visual render `home-*-tablet` (manual review) |
