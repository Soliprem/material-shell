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
          cp *.qml "$out/share/material-shell/"
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
      media-source =
        pkgs.runCommand "material-shell-media-source" {
          nativeBuildInputs = [pkgs.nodejs];
        } ''
          node ${./qml}/test-media-source.cjs
          touch "$out"
        '';
    });

    devShells = forSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = [pkgs.quickshell pkgs.coreutils pkgs.nodejs pkgs.alejandra];
      };
    });
  };
}
