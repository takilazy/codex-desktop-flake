# ChatGPT/Codex desktop for Nix

This flake repackages OpenAI's official Linux `.deb` for the ChatGPT desktop
app, which includes Codex. It supports `x86_64-linux` and `aarch64-linux` and
pins the immutable package URL and SHA-256 from OpenAI's stable APT repository.

Because the app is proprietary, enable unfree packages when running or
installing it:

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix run --impure
```

Build it without launching:

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix build --impure
```

Install it into your user profile:

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure .#chatgpt
```

Or add the flake as an input and use either `packages.<system>.chatgpt` or the
provided overlay's `pkgs.chatgpt` package.

The upstream `latest/chatgpt_amd64.deb` URL is intentionally not used because
it is overwritten on every release, which would break Nix's fixed-output hash.
To update this flake, read the newest `Version`, `Filename`, and `SHA256` fields
from OpenAI's APT indexes:

- `https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages`
- `https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-arm64/Packages`
