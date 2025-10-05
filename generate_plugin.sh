#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="Kyros Recipe Manager By Farhan"
PLUGIN_SLUG="kyros-recipe-manager-Farhan"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"
ZIP_PATH="$SCRIPT_DIR/${PLUGIN_SLUG}.zip"
PLUGIN_SRC_DIR="$SCRIPT_DIR/plugin-src"
PLUGIN_BUILD_DIR="$SCRIPT_DIR/$PLUGIN_SLUG"

if [ ! -d "$PLUGIN_SRC_DIR" ]; then
  echo "❌ Source directory '$PLUGIN_SRC_DIR' not found. Keep the plugin files inside plugin-src/."
  exit 1
fi

rm -rf "$PLUGIN_BUILD_DIR"
mkdir -p "$PLUGIN_BUILD_DIR"

tar -C "$PLUGIN_SRC_DIR" -cf - . | tar -C "$PLUGIN_BUILD_DIR" -xf -

command -v zip >/dev/null 2>&1 || { echo "❌ 'zip' command not found. Install it (apt-get install zip / brew install zip) and re-run."; exit 1; }

rm -f "$ZIP_PATH"

(
  cd "$SCRIPT_DIR"
  zip -rq "$ZIP_PATH" "$PLUGIN_SLUG" -x "*/.DS_Store" "*/node_modules/*" "*/.git/*"
)

(
  cd "$SCRIPT_DIR"
  zip -qj "$ZIP_PATH" "$SCRIPT_PATH"
)

echo "✅ Packaged: $ZIP_PATH"
echo "Next: WordPress Admin → Plugins → Add New → Upload Plugin → select ${PLUGIN_SLUG}.zip → Install → Activate."
