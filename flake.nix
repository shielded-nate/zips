{
  description = "Build and develop the Zcash ZIPs repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/50ab793786d9de88ee30ec4e4c24fb4236fc2674";
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
    dprint-markdown-plugin = {
      url = "path:./tools/dprint/markdown-0.19.0.wasm";
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
          python3Packages.pip
          pandoc
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
              export PYTHONUSERBASE="$PWD/.python-user"
              export PATH="$PYTHONUSERBASE/bin:$PATH"
              python3 -m pip install --quiet --disable-pip-version-check --user rst2html5
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
          shellHook = ''
            export PYTHONUSERBASE="$PWD/.python-user"
            export PATH="$PYTHONUSERBASE/bin:$PATH"
            if ! command -v rst2html5 >/dev/null 2>&1; then
              python3 -m pip install --quiet --disable-pip-version-check --user rst2html5
            fi
          '';
        };
      });
}
