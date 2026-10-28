{
  description = "OpenAI ChatGPT/Codex desktop app, repackaged from the official Debian package";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "26.1023.51421";
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      debs = {
        x86_64-linux = {
          arch = "amd64";
          hash = "sha256-RITcK1T8CXi+sjuNjXF0lOTgtPvqsKh2c5EF5QtE3lo=";
        };
        aarch64-linux = {
          arch = "arm64";
          hash = "sha256-50eNhPKTjdNz+mHFKw8gCwfWEOSJRwUr2K10dpt/0/s=";
        };
      };
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          deb = debs.${system};
        in rec {
          chatgpt = pkgs.stdenv.mkDerivation {
            pname = "chatgpt";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_${deb.arch}.deb";
              inherit (deb) hash;
            };

            nativeBuildInputs = with pkgs; [
              autoPatchelfHook
              dpkg
              makeWrapper
            ];

            buildInputs = with pkgs; [
              alsa-lib
              at-spi2-atk
              at-spi2-core
              atk
              cairo
              cups
              dbus
              expat
              gcc.cc.lib
              gdk-pixbuf
              glib
              gtk3
              libdrm
              libgbm
              libGL
              libnotify
              libpulseaudio
              libsecret
              libusb1
              libxkbcommon
              mesa
              nspr
              nss
              openssl
              pango
              systemd
              tpm2-tss
              vulkan-loader
              libx11
              libxcb
              libxcomposite
              libxdamage
              libxext
              libxfixes
              libxrandr
              libxshmfence
            ];

            runtimeDependencies = with pkgs; [
              libudev-zero
              mesa
            ];

            # The vendor archive contains unused musl prebuilds alongside the
            # glibc prebuilds selected on NixOS.
            autoPatchelfIgnoreMissingDeps = [
              "libc.musl-x86_64.so.1"
              "libc.musl-aarch64.so.1"
              "libQt5Core.so.5"
              "libQt5Gui.so.5"
              "libQt5Widgets.so.5"
              "libQt6Core.so.6"
              "libQt6Gui.so.6"
              "libQt6Widgets.so.6"
            ];

            unpackPhase = ''
              runHook preUnpack
              dpkg-deb -x "$src" .
              runHook postUnpack
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p "$out"
              cp -r usr/* "$out/"

              substituteInPlace "$out/lib/chatgpt/codex-launcher" \
                --replace-fail \
                  'exec "$(dirname "$(readlink -f "$0")")/ChatGPT" "$@"' \
                  'source_dir="$(dirname "$(readlink -f "$0")")"
runtime_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/chatgpt-nix/${version}"
if [ ! -x "$runtime_dir/ChatGPT" ]; then
  mkdir -p "$(dirname "$runtime_dir")"
  cp -R "$source_dir" "$runtime_dir"
  chmod -R u+w "$runtime_dir"
fi
exec "$runtime_dir/ChatGPT" "$@"'

              wrapProgram "$out/bin/chatgpt" \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git pkgs.xdg-utils ]} \
                --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.vulkan-loader ]}
              runHook postInstall
            '';

            meta = {
              description = "ChatGPT desktop app with Codex by OpenAI";
              homepage = "https://openai.com/codex/";
              license = pkgs.lib.licenses.unfree;
              mainProgram = "chatgpt";
              platforms = systems;
              sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
            };
          };

          default = chatgpt;
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.chatgpt}/bin/chatgpt";
        };
        chatgpt = self.apps.${system}.default;
      });

      overlays.default = final: prev: {
        chatgpt = self.packages.${final.system}.chatgpt;
      };
    };
}
