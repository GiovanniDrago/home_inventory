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

IFS='.' read -r major minor patch <<< "$version"
build_number=$((10#$major * 10000 + 10#$minor * 100 + 10#$patch))
full_version="${version}+${build_number}"

sed -i.bak -E "s/^version: .*/version: ${full_version}/" pubspec.yaml
rm -f pubspec.yaml.bak

git add pubspec.yaml
git commit -m "Bump version to ${full_version}"
git push

git tag -a "$tag" -m "Release $tag"
git push origin "$tag"
