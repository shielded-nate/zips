{
  description = "Build and develop the Zcash ZIPs repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    dprint-markdown-plugin = {
      url = "https://plugins.dprint.dev/markdown-0.19.0.wasm";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    dprint-markdown-plugin,
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        revision = self.shortRev or "unknown";

        commonInputs = with pkgs; [
          gawk
          perl
          gnused
          git
          python3
          python3Packages.rst2html5
          pandoc
          biber
          latexmk
          texlive.combined.scheme-full
        ];

        mkMakeTarget = {
          name,
          target,
          installCmd,
        }:
          pkgs.stdenvNoCC.mkDerivation {
            inherit name;
            src = ./.;
            nativeBuildInputs = commonInputs;
            buildPhase = ''
              runHook preBuild
              cp -a "$src" ./source
              chmod -R u+w ./source
              cd ./source
              sed -i "s/git describe --tags --abbrev=6/echo ${revision}/g" protocol/Makefile
              make ${target}
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p "$out"
              ${installCmd}
              runHook postInstall
            '';
          };
      in {
        packages = {
          all-zips = mkMakeTarget {
            name = "zips-all-zips";
            target = "all-zips";
            installCmd = ''
              cp -r rendered "$out/"
              cp README.rst "$out/"
            '';
          };

          all-specs = mkMakeTarget {
            name = "zips-all-specs";
            target = "all-specs";
            installCmd = ''
              mkdir -p "$out/rendered"
              cp -r rendered/protocol "$out/rendered/"
            '';
          };

          all = mkMakeTarget {
            name = "zips-all";
            target = "all";
            installCmd = ''
              cp -r rendered "$out/"
              cp README.rst "$out/"
            '';
          };

          default = self.packages.${system}.all;
        };

        devShells.default = pkgs.mkShell {
          packages = commonInputs ++ [ pkgs.dprint ];
          DPRINT_MARKDOWN_PLUGIN = "${dprint-markdown-plugin}";
        };
      });
}
