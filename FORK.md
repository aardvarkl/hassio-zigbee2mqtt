# Fork notes

This fork provides a **second Zigbee2MQTT app** ("Zigbee2MQTT 1st Floor") that runs
alongside the official Zigbee2MQTT app in Home Assistant.

- App ID `zigbee2mqtt_1stfloor`, data in `/config/zigbee2mqtt_1stfloor`, MQTT base topic `zigbee2mqtt_1stfloor`
- Uses the official stable image `ghcr.io/zigbee2mqtt/zigbee2mqtt-{arch}`, so the code is identical to the stable app
- Edge and Proxy apps are removed; the socat port is disabled by default to avoid clashing with the main app
- `.github/workflows/sync-upstream.yml` runs daily (or manually), rebuilds the repo from upstream using
  `tools/customise.sh`, and pushes only if something changed. HA then offers the update as usual.

Do not edit files outside `.github/`, `tools/` and this file by hand - the sync overwrites them.
Change the customisation in `tools/customise.sh` instead.
