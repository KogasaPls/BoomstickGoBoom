# Releasing Boomstick Go Boom

## One-time setup

1. Create the public repository `KogasaPls/BoomstickGoBoom`.
2. In the GitHub repository settings, add the Actions secret `CF_API_TOKEN`.
3. In CurseForge, make sure project `1603116` is owned by or shared with the account that created that token.

## Normal release flow

1. Update addon code and metadata on `main`.
2. Bump `## Version:` in `BoomstickGoBoom.toc`.
3. Commit and push `main`.
4. Wait for the `Create Tag and Publish` workflow to create the matching tag and upload the release.

The package workflow validates branch and pull request builds in dry-run mode.
Manual tags are still supported, but the tag must exactly match the `.toc`
version or publishing will fail.

## Notes

- The workflow reads the CurseForge project ID from `BoomstickGoBoom.toc`.
- Release tags are immutable; bump the `.toc` version instead of moving an existing tag.
- Untagged builds are validation-only and do not upload anywhere.
- The local `package.sh` script is still available for manual packaging.
