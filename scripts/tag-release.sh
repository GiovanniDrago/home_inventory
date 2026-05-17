#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tag>" >&2
  exit 1
fi

tag="$1"
version="${tag#v}"

if [[ "$tag" == "$version" ]]; then
  echo "tag must start with v (example: v1.2.3)" >&2
  exit 1
fi

if [[ ! -f "pubspec.yaml" ]]; then
  echo "pubspec.yaml not found" >&2
  exit 1
fi

if ! grep -q "^version:" pubspec.yaml; then
  echo "version field not found in pubspec.yaml" >&2
  exit 1
fi

sed -i.bak -E "s/^version: .*/version: ${version}/" pubspec.yaml
rm -f pubspec.yaml.bak

git add pubspec.yaml
git commit -m "Bump version to ${tag}"
git push

git tag -a "$tag" -m "Release $tag"
git push origin "$tag"
