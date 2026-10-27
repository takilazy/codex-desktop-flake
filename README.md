# ChatGPT/Codex desktop for Nix

This flake repackages OpenAI's official Linux `.deb` for the ChatGPT desktop
app, which includes Codex. It supports `x86_64-linux` and `aarch64-linux` and
pins the immutable package URL and SHA-256 from OpenAI's stable APT repository.

Because the app is proprietary, enable unfree packages when running or
installing it:

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:takilazy/codex-desktop-flake
```

Build it without launching:

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix build --impure github:takilazy/codex-desktop-flake#chatgpt
```

Install it into your user profile:

```console
$ NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure github:takilazy/codex-desktop-flake#chatgpt
```

## Flake-based NixOS configuration

Add this repository as an input and install its package directly:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    codex-desktop = {
      url = "github:takilazy/codex-desktop-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, codex-desktop, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;
          environment.systemPackages = [
            codex-desktop.packages.${pkgs.system}.chatgpt
          ];
        })
      ];
    };
  };
}
```

You can instead use the provided overlay:

```nix
nixpkgs.overlays = [ codex-desktop.overlays.default ];
nixpkgs.config.allowUnfree = true;
environment.systemPackages = [ pkgs.chatgpt ];
```

## Traditional `configuration.nix`

A NixOS installation that does not manage its configuration with a flake can
load the package with `builtins.getFlake`:

```nix
{ pkgs, ... }:

let
  codex-desktop = builtins.getFlake "github:takilazy/codex-desktop-flake";
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    codex-desktop.packages.${pkgs.system}.chatgpt
  ];
}
```

Then apply it normally:

```console
$ sudo nixos-rebuild switch
```

Although the system configuration itself remains non-flake-based, the `flakes`
feature is needed so `builtins.getFlake` can fetch this package.

## Updates

The upstream `latest/chatgpt_amd64.deb` URL is intentionally not used because
it is overwritten on every release, which would break Nix's fixed-output hash.
To update this flake, read the newest `Version`, `Filename`, and `SHA256` fields
from OpenAI's APT indexes:

- `https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages`
- `https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-arm64/Packages`
