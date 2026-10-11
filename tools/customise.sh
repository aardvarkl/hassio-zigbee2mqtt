#!/usr/bin/env bash
# Rebuilds this fork from upstream zigbee2mqtt/hassio-zigbee2mqtt and turns the
# stable Zigbee2MQTT app into a second, independent instance for the 1st floor.
#
# Usage: tools/customise.sh <upstream-checkout> <fork-worktree>
#
# Only the stable app is kept (Edge/Proxy removed). Its ID, name, data folder,
# MQTT base topic and socat port are changed so it can run alongside the
# official Zigbee2MQTT app. The Docker image is still the official stable one.
set -euo pipefail

UP="$(cd "$1" && pwd)"
FORK="$(cd "$2" && pwd)"

SRC_DIR="zigbee2mqtt"
DST_DIR="zigbee2mqtt-1stfloor"
NAME="Zigbee2MQTT 1st Floor"
SLUG="zigbee2mqtt_1stfloor"
DATA_PATH="/config/zigbee2mqtt_1stfloor"
BASE_TOPIC="zigbee2mqtt_1stfloor"
REPO_URL="https://github.com/aardvarkl/hassio-zigbee2mqtt"

# Sanity checks on upstream layout - fail loudly rather than publish a broken app
[[ -f "$UP/$SRC_DIR/config.json" ]] || { echo "upstream $SRC_DIR/config.json missing"; exit 1; }
[[ "$(jq -r .slug "$UP/$SRC_DIR/config.json")" == "zigbee2mqtt" ]] || { echo "unexpected upstream slug"; exit 1; }
[[ "$(jq -r .options.data_path "$UP/$SRC_DIR/config.json")" == "/config/zigbee2mqtt" ]] || { echo "unexpected upstream data_path"; exit 1; }
jq -e '.image' "$UP/$SRC_DIR/config.json" >/dev/null || { echo "upstream no longer uses a prebuilt image"; exit 1; }

# Wipe everything except git metadata and our own files, then copy upstream in
find "$FORK" -mindepth 1 -maxdepth 1 \
  ! -name .git ! -name .github ! -name tools ! -name FORK.md \
  -exec rm -rf {} +
(cd "$UP" && tar cf - --exclude=./.git --exclude=./.github .) | (cd "$FORK" && tar xf -)

# Keep only the stable app, renamed
rm -rf "$FORK/zigbee2mqtt-edge" "$FORK/zigbee2mqtt-proxy"
mv "$FORK/$SRC_DIR" "$FORK/$DST_DIR"

CFG="$FORK/$DST_DIR/config.json"
jq --indent 2 \
  --arg name "$NAME" --arg slug "$SLUG" --arg dp "$DATA_PATH" \
  --arg bt "$BASE_TOPIC" --arg url "$REPO_URL/tree/master/$DST_DIR" '
  .name = $name
  | .slug = $slug
  | .description = "Second Zigbee2MQTT instance (1st floor / attic network)"
  | .url = $url
  | .panel_title = "Z2M 1st Floor"
  | .options.data_path = $dp
  | .options.mqtt.base_topic = $bt
  | .ports["8485/tcp"] = null
' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"

jq --indent 2 --arg url "$REPO_URL" '
  .name = "Sean - Zigbee2MQTT extra instances"
  | .url = $url
' "$FORK/repository.json" > "$FORK/repository.json.tmp" && mv "$FORK/repository.json.tmp" "$FORK/repository.json"

echo "Customised: $(jq -r '.name + " " + .version' "$CFG")"
