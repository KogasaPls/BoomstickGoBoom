# Releasing Boomstick Go Boom

## One-time setup

1. Create the public repository `KogasaPls/BoomstickGoBoom`.
2. In the GitHub repository settings, add the Actions secret `CF_API_TOKEN`.
3. In CurseForge, make sure project `1603116` is owned by or shared with the account that created that token.

## Normal release flow

1. Update addon code and metadata on `main`.
2. Bump `## Version:` in `BoomstickGoBoom.toc`.
3. Commit and push `main`.
4. Create and push a tag that matches the addon version, for example `v1.0.0`.
5. Wait for the `Package and Publish` workflow to finish.

The workflow packages branch and pull request builds in dry-run mode, then publishes tagged builds to CurseForge.

## Notes

- The workflow reads the CurseForge project ID from `BoomstickGoBoom.toc`.
- Untagged builds are validation-only and do not upload anywhere.
- The local `package.sh` script is still available for manual packaging.
