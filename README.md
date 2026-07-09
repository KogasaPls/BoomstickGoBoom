# Boomstick Go Boom

Boomstick Go Boom is a small World of Warcraft addon for Survival Hunters. It plays four timed "tick" sounds while you channel Boomstick so the cadence is easier to follow without staring at the cast bar.

## Installation

1. Download the latest packaged zip from CurseForge, or build one locally with `./package.sh`.
2. Extract `BoomstickGoBoom` into your `_retail_/Interface/AddOns/` directory.
3. Log in on a Survival Hunter and use `/bgb test`.

## Commands

- `/bgb channel Master|SFX|Ambience|Music|Dialog`
- `/bgb test`

## Preview

[Video preview](docs/media/boomcat2.mp4)

## Packaging And Releases

This repo includes a GitHub Actions workflow that packages every push and publishes tagged releases to CurseForge with the BigWigs WoW packager.

1. Add the repository secret `CF_API_TOKEN` with a CurseForge API token from the project owner account.
2. Push a tag like `v1.0.0`.
3. GitHub Actions will build the addon and upload it to CurseForge project `1603116`.

See [RELEASING.md](RELEASING.md) for the exact release flow.

## Licensing

The addon code is MIT licensed. The included sound files have separate attribution and redistribution notes in [NOTICE.md](NOTICE.md).
