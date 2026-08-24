# Publishing Local Stray

Local Stray has four required, independently reviewable release units:

1. `adrianmurray/Qwen3.8-27B-Hybrid-Q8Q4` on Hugging Face: recommended target weights.
2. `adrianmurray/Qwen3.8-27B-MTP-MLX-6bit` on Hugging Face: matching native-MTP draft.
3. `titofebus/LocalStrayRuntime` on GitHub: owner-controlled runtime mirror and
   wheel source, seeded from `adriancmurray/qwen-prime-runtime`.
4. `LOCAL_STRAY_RELEASE_REPOSITORY` on GitHub: the owner-selected canonical
   Local Stray source, Sparkle appcast, and notarized app archive.

`adrianmurray/Qwen3.8-27B-MLX-6bit` remains available as the uniform 6-bit
baseline and optional target.

The model repositories are not downloaded automatically. The app asks the user
to choose both folders and stores only their paths in
`~/Library/Application Support/LocalStray/runtime.json`. The Python runtime is
embedded in every public app archive and therefore updates with Sparkle.

## Runtime mirror

[`titofebus/LocalStrayRuntime`](https://github.com/titofebus/LocalStrayRuntime)
is the Local Stray-owned runtime source. It was seeded from
[`adriancmurray/qwen-prime-runtime`](https://github.com/adriancmurray/qwen-prime-runtime),
which remains the upstream to monitor. Before taking an upstream change, fetch
it, review the diff and licenses, run the runtime tests, fast-forward the mirror,
and push the reviewed result and tags. The mirror's `UPSTREAM.md` records the
seed revision and repeatable synchronization commands.

## Non-secret preflight

From the Local Stray checkout:

```bash
swift package resolve
./release_preflight.command 1.1.1
```

The preflight validates local tools, Sparkle artifacts, the appcast, and release
scripts. It reports credential names but never reads or prints their values.

From the runtime checkout:

```bash
uv sync --extra dev
uv run pytest
uv build --wheel
./scripts/build_embedded_runtime.command /private/tmp/LocalStrayRuntime
/private/tmp/LocalStrayRuntime/bin/qwen-prime-runtime --help
```

Move the payload before the final command when testing relocation. Run `doctor`
with the release model pair selected.

## Final credential checkpoint

Keep these values outside the repositories and inject them only into the final
release command:

- `DEVELOPER_ID_APPLICATION`: the Developer ID Application identity name.
- Apple notarization: either `NOTARY_PROFILE`, or `APPLE_ID`, `APPLE_TEAM_ID`,
  and `NOTARY_APP_PASSWORD`. The latter can be injected command-scoped from an
  existing Vault app-specific password without creating a Keychain profile.
- `SPARKLE_PUBLIC_ED_KEY`: the public Sparkle Ed25519 key embedded in the app.
- `SPARKLE_ACCOUNT` (default `app.dech.localstray`): the Keychain account used
  by Sparkle to read the matching private signing seed.
- `LOCAL_STRAY_RELEASE_REPOSITORY`: the canonical GitHub `owner/repository`.
- `SPARKLE_FEED_URL`: the canonical HTTPS appcast URL. The publisher derives
  `https://raw.githubusercontent.com/<owner>/<repository>/main/appcast.xml`
  when it is omitted.
- GitHub CLI authorization with repository and release access.
- `HF_TOKEN` with write access to the model repositories.

Do not put private values in shell history, source files, app resources,
appcasts, logs, or GitHub Actions output.

## Initial publication order

1. Create the two Hugging Face model repositories and upload each verified
   directory with `hf upload-large-folder`.
2. Maintain the curated runtime source and wheel in
   `titofebus/LocalStrayRuntime`, syncing reviewed updates from
   `adriancmurray/qwen-prime-runtime`.
3. Publish the prepared Local Stray source at the owner-selected canonical
   repository, then configure its GitHub redirect strategy if applicable.
4. Inject the Apple, Sparkle, GitHub, and canonical repository values and run:

   ```bash
   ./publish_release.command 1.1.1
   ```

The command requires committed source, builds the locked embedded runtime,
signs the complete app with hardened runtime, notarizes and staples it, creates
the archive and checksum, signs the Sparkle appcast, commits that appcast, tags
the release, pushes it, and creates the GitHub Release.

## Future app and runtime updates

Update the app and/or runtime source, update the locked dependency versions,
run both test suites and the non-secret preflight, then run
`publish_release.command` with a new semantic version. No Cloudflare worker,
Studio Admin deployment, or secondary update monitor is involved. Sparkle reads
the GitHub-hosted appcast only when the user presses **Check for Updates**.

Model artifacts need a new revision only when their actual weights or metadata
change. Ordinary app and runtime releases continue using the model paths already
stored in Application Support.
