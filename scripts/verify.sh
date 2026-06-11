#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "== Server tests =="
(cd apps/server && npm test)

echo "== iOS metadata =="
xmllint --noout apps/ios/SnapMotion.xcodeproj/xcshareddata/xcschemes/SnapMotion.xcscheme
plutil -lint apps/ios/SnapMotion/Supporting/Info.plist

echo "== Xcode project references =="
node <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const root = process.cwd();
const pbx = fs.readFileSync(path.join(root, "apps/ios/SnapMotion.xcodeproj/project.pbxproj"), "utf8");
const roots = ["SnapMotion", "SnapMotionTests", "SnapMotionUITests"];

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const filePath = path.join(dir, entry.name);
    if (entry.isDirectory()) return walk(filePath);
    return entry.name.endsWith(".swift") ? [filePath] : [];
  });
}

const missing = [];
let total = 0;
for (const targetRoot of roots) {
  const rootPath = path.join(root, "apps/ios", targetRoot);
  const files = walk(rootPath).map((filePath) => path.relative(rootPath, filePath));
  total += files.length;
  for (const file of files) {
    if (!pbx.includes(`path = ${file};`) && !pbx.includes(`path = "${file}";`)) {
      missing.push(`${targetRoot}/${file}`);
    }
  }
}

const stale = [];
for (const match of pbx.matchAll(/path = ([^;]+\.swift);/g)) {
  const ref = match[1].replace(/^"|"$/g, "");
  if (!roots.some((targetRoot) => fs.existsSync(path.join(root, "apps/ios", targetRoot, ref)))) {
    stale.push(ref);
  }
}

if (missing.length || stale.length) {
  console.error(JSON.stringify({ missing, stale }, null, 2));
  process.exit(1);
}

console.log(`Validated ${total} Swift source references.`);
NODE

echo "== Avatar rig morph targets =="
plutil -p apps/ios/SnapMotion/Resources/AvatarAssets.scnassets/CuteAvatarTemplate.scn \
  | rg "blink_L|blink_R|jaw_open|smile_L|smile_R|brow_up_L|brow_up_R|mouth_funnel|mouth_pucker|cheek_squint_L|cheek_squint_R" >/dev/null

echo "== Xcode build =="
if ! xcodebuild -project apps/ios/SnapMotion.xcodeproj -scheme SnapMotion -destination 'generic/platform=iOS Simulator' build; then
  echo "xcodebuild failed. If the output mentions the Xcode license, run: sudo xcodebuild -license" >&2
  exit 1
fi
