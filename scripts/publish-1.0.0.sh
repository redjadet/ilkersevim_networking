#!/usr/bin/env bash
# Run on a machine authenticated as GitHub user redjadet (not cursor[bot]).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== auth =="
gh auth status
LOGIN="$(gh api user --jq .login)"
echo "login=$LOGIN"
test "$LOGIN" = "redjadet"

if [ ! -d .git ]; then
  git init -b main
  git remote add origin https://github.com/redjadet/ilkersevim_networking.git 2>/dev/null || \
    git remote set-url origin https://github.com/redjadet/ilkersevim_networking.git
fi

echo "== commit =="
git add -A
if git diff --cached --quiet; then
  echo "nothing to commit (already staged/committed?)"
else
  git -c user.email="ilkersevim2007@gmail.com" -c user.name="İlker Sevim" \
    commit -m "feat: IlkerSevimNetworking 1.0.0 initial public release"
fi

echo "== push main =="
git push -u origin main

echo "== tag + release =="
git tag -a 1.0.0 -m "IlkerSevimNetworking 1.0.0" 2>/dev/null || true
git push origin 1.0.0
gh release create 1.0.0 \
  --title "1.0.0" \
  --notes "Initial public release: URLSession networking with retry, idempotent POST, and token refresh." \
  2>/dev/null || gh release view 1.0.0

if command -v pod >/dev/null 2>&1; then
  echo "== pod lib lint =="
  pod lib lint IlkerSevimNetworking.podspec --allow-warnings || true
  if pod trunk me >/dev/null 2>&1; then
    pod trunk push IlkerSevimNetworking.podspec --allow-warnings
  else
    echo "CocoaPods trunk session missing — podspec ready, SPM shipped."
  fi
else
  echo "pod not installed — skipping CocoaPods lint"
fi

echo "DONE sha=$(git rev-parse HEAD)"
