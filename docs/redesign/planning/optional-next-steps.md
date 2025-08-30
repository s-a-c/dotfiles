# Optional Next Steps – CI/CD & Automation Scaffold
Date: 2025-08-30
Status: Informational (Templates Only)

This document provides scaffold examples for the optional enhancements previously mentioned (workflows, hooks, notifier scripts). These can be adopted incrementally after core refactor phases (1–12) are stable.

## 1. GitHub Actions Workflow Templates
All YAML files go under `.github/workflows/`.

### 1.1 Core CI (ci-core.yml)
Purpose: Run structure/design, unit, feature, integration, security tests on push & PR.
```yaml
name: CI Core
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
jobs:
  test:
    name: Test Matrix
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v4
      - name: Set up Zsh
        run: echo "SHELL=$(which zsh)" >> $GITHUB_ENV
      - name: Cache Zgenom
        uses: actions/cache@v4
        with:
          path: ~/.zgenom
          key: zgenom-${{ runner.os }}-${{ hashFiles('**/trusted-plugins.json') }}
      - name: Run Core Tests
        shell: zsh {0}
        run: |
          chmod +x tests/run-all-tests.zsh || true
          tests/run-all-tests.zsh --category=design,unit,feature,integration,security --json-report || exit 1
      - name: Upload Test Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: core-tests-${{ matrix.os }}
          path: docs/redesign/reports/latest-test.json
```

### 1.2 Performance (ci-performance.yml)
Purpose: Nightly + manual startup benchmark & regression detection.
```yaml
name: CI Performance
on:
  workflow_dispatch: {}
  schedule:
    - cron: '0 3 * * *'
jobs:
  perf:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Performance Harness
        shell: zsh {0}
        run: |
          if [[ -x bin/test-performance.zsh ]]; then
            bin/test-performance.zsh --runs 10 --json-out perf-current.json
          else
            echo '{"error":"missing harness"}' > perf-current.json
          fi
      - name: Compare Against Baseline
        shell: zsh {0}
        run: |
          BASE=docs/redesign/metrics/perf-baseline.json
          CUR=perf-current.json
          if [[ -f $BASE && -f $CUR ]]; then
            mean_base=$(grep -E 'startup_mean_ms' $BASE | tr -dc '0-9.')
            mean_cur=$(grep -E 'startup_mean_ms' $CUR | tr -dc '0-9.')
            if [[ -n $mean_base && -n $mean_cur ]]; then
              pct=$(awk -v b="$mean_base" -v c="$mean_cur" 'BEGIN{ printf "%.2f", (c-b)/b*100 }')
              echo "Delta %: $pct"
              awk -v p="$pct" 'BEGIN{ exit (p>5?1:0) }'
            fi
          fi
      - name: Upload Perf Artifact
        uses: actions/upload-artifact@v4
        with:
          name: perf-current
          path: perf-current.json
      - name: Email on Regression
        if: failure()
        uses: dawidd6/action-send-mail@v3
        with:
          server_address: ${{ secrets.SMTP_SERVER }}
          server_port: ${{ secrets.SMTP_PORT }}
          username: ${{ secrets.SMTP_USER }}
          password: ${{ secrets.SMTP_PASS }}
          subject: '[zsh-refactor] Performance Regression'
          to: ${{ secrets.ALERT_EMAIL }}
          from: 'ci@zsh-refactor'
          content_type: text/plain
          body: |
            Performance regression detected (>5%). See artifact perf-current.json.
```

### 1.3 Security (ci-security.yml)
Purpose: Nightly integrity scan & tamper detection.
```yaml
name: CI Security
on:
  workflow_dispatch: {}
  schedule:
    - cron: '30 3 * * *'
jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Security Tests
        shell: zsh {0}
        run: |
          chmod +x tests/run-all-tests.zsh || true
          tests/run-all-tests.zsh --category=security --json-report || exit 1
      - name: Upload Security Report
        uses: actions/upload-artifact@v4
        with:
          name: security-report
          path: docs/redesign/reports/latest-test.json
      - name: Notify on Failure
        if: failure()
        uses: dawidd6/action-send-mail@v3
        with:
          server_address: ${{ secrets.SMTP_SERVER }}
          server_port: ${{ secrets.SMTP_PORT }}
          username: ${{ secrets.SMTP_USER }}
          password: ${{ secrets.SMTP_PASS }}
          subject: '[zsh-refactor] Security Scan Failure'
          to: ${{ secrets.ALERT_EMAIL }}
          from: 'ci@zsh-refactor'
          content_type: text/plain
          body: 'Security scan failed; review latest artifact.'
```

## 2. Sample Pre-Commit Hook (`.git/hooks/pre-commit`)
(Not version-controlled by default; user installs manually.)
```bash
#!/usr/bin/env bash
CHANGED=$(git diff --cached --name-only)
if ! echo "$CHANGED" | grep -vq '^docs/'; then
  echo '[pre-commit] Only docs changed → skipping tests.'
  exit 0
fi
if [[ -x tests/run-all-tests.zsh ]]; then
  echo '[pre-commit] Running unit+integration+security tests...'
  tests/run-all-tests.zsh --category=unit,integration,security --fail-fast || { echo '[pre-commit] Tests failed'; exit 1; }
fi
if [[ -x bin/test-performance.zsh ]]; then
  echo '[pre-commit] Quick performance check...'
  bin/test-performance.zsh --quick --json-out .git/perf-quick.json || true
  BASE=docs/redesign/metrics/perf-baseline.json
  CUR=.git/perf-quick.json
  if [[ -f $BASE && -f $CUR ]]; then
    base=$(grep -E 'startup_mean_ms' "$BASE" | tr -dc '0-9.')
    cur=$(grep -E 'startup_mean_ms' "$CUR" | tr -dc '0-9.')
    if [[ -n $base && -n $cur ]]; then
      delta=$(awk -v b="$base" -v c="$cur" 'BEGIN{ printf "%.2f", (c-b)/b*100 }')
      echo "[pre-commit] Perf delta: ${delta}%"
      awk -v d="$delta" 'BEGIN{ exit (d>5?1:0) }' || { echo '[pre-commit] >5% perf regression'; exit 1; }
    fi
  fi
fi
exit 0
```

## 3. Notifier Script (`tools/notify-email.zsh` Example)
Purpose: Unified email / summary composition; can fallback to stdout when SMTP not configured.
```zsh
#!/usr/bin/env zsh
set -eu
subject=${1:-"[zsh-refactor] Notification"}
shift || true
body_file=${1:-"-"}
if [[ "$body_file" != "-" && -f "$body_file" ]]; then
  body=$(<"$body_file")
else
  body="No body provided."
fi
if [[ -n ${SMTP_SERVER:-} && -n ${ALERT_EMAIL:-} ]]; then
  print -r -- "$body" | mail -s "$subject" "$ALERT_EMAIL" || {
    echo "[notify] mail send failed; falling back to stdout" >&2
    echo "$body"
  }
else
  echo "[notify] SMTP not configured; printing body" >&2
  echo "$body"
fi
```

## 4. Cron-Friendly Wrapper (`tools/run-nightly-maintenance.zsh`)
Combines performance capture, security scan, summary generation, notification.
```zsh
#!/usr/bin/env zsh
set -euo pipefail
LOG_DIR=${ZDOTDIR:-$HOME/.config/zsh}/logs/nightly
mkdir -p "$LOG_DIR"
STAMP=$(date +%Y-%m-%dT%H-%M-%S)
OUT="$LOG_DIR/nightly-$STAMP.log"
exec > >(tee -a "$OUT") 2>&1

echo "[nightly] Start $STAMP"
if [[ -x tools/perf-capture.zsh ]]; then
  echo "[nightly] Performance capture"
  tools/perf-capture.zsh || echo '[nightly] perf capture failed'
fi
if [[ -x tools/weekly-security-maintenance ]]; then
  echo "[nightly] Security maintenance (light)"
  tools/weekly-security-maintenance --light || echo '[nightly] security maintenance failed'
fi
SUMMARY=$(mktemp)
{
  echo "# Nightly Summary $STAMP"
  echo "## Performance"
  grep -i delta logs/perf-cron.log | tail -n 5 || true
  echo "## Security"
  grep -i violation logs/security-weekly.log | tail -n 20 || echo 'No recent violations'
} > "$SUMMARY"
if [[ -x tools/notify-email.zsh ]]; then
  ALERT_EMAIL=${ALERT_EMAIL:-embrace.s0ul+s-a-c-zsh@gmail.com} tools/notify-email.zsh "[zsh-refactor] Nightly Summary" "$SUMMARY"
fi
rm -f "$SUMMARY"
echo "[nightly] Done"
```

## 5. Badge Generation (Optional)
- Use a small script (Python or shell with jq) to compute last perf delta and output a JSON shield: place artifact in `docs/badges/perf.json`.
- Consume via shields.io endpoint or gh-pages.

## 6. Secrets & Environment
Define GitHub repo secrets:
- ALERT_EMAIL: embrace.s0ul+s-a-c-zsh@gmail.com
- SMTP_SERVER / SMTP_PORT / SMTP_USER / SMTP_PASS (if using send-mail action)

## 7. Adoption Order Recommendation
1. Add core CI workflow.
2. Establish baseline perf JSON; then add performance workflow.
3. Add security workflow & notifier.
4. Introduce pre-commit hook to local clones (not versioned by default).
5. Layer in nightly maintenance wrapper & cron (local environment only).
6. Add enhancements (zcompile pass, diff alerts) gating with new tests.

## 8. Rollback of Automation
- Disable workflows: remove YAML or limit trigger branches.
- Remove cron: delete crontab entry or launchd plist referencing wrapper.
- Keep notifier script; harmless without SMTP configuration.

---
(End of optional next steps scaffold.)
