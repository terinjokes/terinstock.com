{ pkgs ? import ./nix/pkgs.nix { }, ... }:

with pkgs;

let
  python = python3.withPackages (ps: with ps; [ pygments ]);
  hugo = callPackage ./nix/hugo.nix { };
  site = stdenvNoCC.mkDerivation {
    name = "terinstock.com";
    src = ./.;
    buildInputs = [ python ];

    phases = [ "unpackPhase" "buildPhase" ];

    buildPhase = ''
      ${hugo}/bin/hugo -d $out
    '';
  };

in {
  inherit python hugo site;
  publish = runCommand "release publish" {
    preferLocalBuild = true;
    allowSubstitues = false;
    shellHookOnly = true;
    shellHook = ''
      echo "Uploading from ${site}..."
      ${rsync}/bin/rsync -az --stats --rsh="${openssh}/bin/ssh -o LogLevel=ERROR -l terin" ${site}/ $RSYNC_HOST::site-terinstock
      exit 0
    '';
  } ''
    echo "This derivation is not buildable, instead run it with nix-shell."
    exit 1
  '';
}
