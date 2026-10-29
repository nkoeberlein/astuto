# Releasing

Versions follow [Semantic Versioning](https://semver.org); pre-releases are `2.0.0-alpha.N`,
`2.0.0-beta.N`, `2.0.0-rc.N`.

## Checklist

1. **Main is green:** CI (`run-tests.yml`, `frontend.yml`, `lint.yml`, `helm.yml`) passes on the
   commit to release. Locally: `docker compose exec web bin/ci` and `npm run e2e` in `frontend/`.
2. **Upgrade notes:** anything operators must do (new ENV variables, migrations that take long,
   changed defaults) is in `UPGRADING.md` and in the changelog.
3. **Version** in all four places, same number:
   - `config/initializers/project.rb` (`AstutoProject::VERSION`)
   - `frontend/package.json` and `frontend/package-lock.json` (`npm version <version> --no-git-tag-version` in `frontend/`)
   - `deploy/helm/astuto-evolution/Chart.yaml`: `appVersion`, and raise the chart `version` when the chart changed
4. **Changelog:** rename `## [Unreleased]` to `## [<version>] – <YYYY-MM-DD>`, add a new empty
   `## [Unreleased]` above it. Sections: Removed, Changed, Security, Features, Fixes.
5. **Commit** "Release <version>", then a signed tag:
   ```bash
   git tag -s v<version> -m "Astuto Evolution <version>"
   git push origin main v<version>
   ```
6. **Images:** the tag starts `push-to-registry.yml`. It builds `linux/amd64` and `linux/arm64`,
   pushes `ghcr.io/<owner>/astuto-evo:<version>` and `:<major>.<minor>` (and `:latest` from
   main), attaches provenance and an SBOM, and signs the image with cosign.
7. **GitHub release:** create it from the tag; the notes are the changelog section of the
   version. Mark alphas, betas and release candidates as pre-release.
8. **Check:** pull the image and verify its signature (below); start it once against a copy of
   a real database if the release has migrations.

## Verifying an image

The images are signed keylessly: the signature names the GitHub workflow that built them.

```bash
cosign verify ghcr.io/nkoeberlein/astuto-evo:<version> \
  --certificate-identity-regexp '^https://github.com/nkoeberlein/astuto-evo/\.github/workflows/push-to-registry\.yml@refs/(heads/main|tags/v.+)$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

The SBOM and provenance can be read with
`docker buildx imagetools inspect ghcr.io/nkoeberlein/astuto-evo:<version> --format '{{ json .SBOM }}'`
(or `.Provenance`).
