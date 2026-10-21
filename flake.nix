{
  description = "Material desktop sidebar and notifications for Quickshell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    forSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    packages = forSystems (system: let
      pkgs = pkgsFor system;
    in rec {
      default = material-shell;
      material-shell = pkgs.stdenvNoCC.mkDerivation {
        pname = "material-shell";
        version = "0.1.0";
        src = ./qml;
        nativeBuildInputs = [pkgs.makeWrapper];
        dontBuild = true;

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/share/material-shell"
          cp [A-Z]*.qml shell.qml "$out/share/material-shell/"
          install -Dm644 ${./LICENSE} "$out/share/licenses/material-shell/LICENSE"
          makeWrapper ${pkgs.quickshell}/bin/quickshell "$out/bin/material-shell" \
            --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.bash pkgs.coreutils]} \
            --add-flags "--path $out/share/material-shell"
          runHook postInstall
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck
          "$out/bin/material-shell" --version
          runHook postInstallCheck
        '';

        meta = {
          description = "Material desktop sidebar and notification daemon";
          license = pkgs.lib.licenses.gpl3Only;
          mainProgram = "material-shell";
          platforms = pkgs.lib.platforms.linux;
        };
      };
    });

    checks = forSystems (system: let
      pkgs = pkgsFor system;
    in {
      package = self.packages.${system}.default;
      shell =
        pkgs.runCommand "material-shell-checks" {
          nativeBuildInputs = [pkgs.quickshell pkgs.dbus pkgs.bash pkgs.coreutils];
        } ''
          export QT_QPA_PLATFORM=offscreen
          export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
          export XDG_CACHE_HOME="$TMPDIR/cache"
          export XDG_RUNTIME_DIR="$TMPDIR/runtime"
          mkdir -m700 "$XDG_RUNTIME_DIR"
          timeout 15 dbus-run-session --config-file=${pkgs.dbus}/share/dbus-1/session.conf -- \
            quickshell --no-color --path ${./qml}/test-shell.qml > test.log 2>&1 \
            || { cat test.log; exit 1; }
          cat test.log
          grep -q 'Shell checks passed' test.log
          if grep -E '(ERROR|WARN scene)' test.log; then exit 1; fi
          touch "$out"
        '';
    });

    devShells = forSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = [pkgs.quickshell pkgs.alejandra];
      };
    });
  };
}
