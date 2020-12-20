{ pkgs, ... }:

pkgs.buildGoPackage rec {
  pname = "hugo";
  version = "v0.20.7";

  src = pkgs.fetchFromGitHub {
    owner = "gohugoio";
    repo = "hugo";
    rev = version;
    sha256 = "18r8jnq6mnkigh6i2vq7ldvizdi5kyl96bclyh82y2cv6izj9lmi";
  };

  goPackagePath = "github.com/spf13/hugo";
  deleteVendor = true;
  goDeps = ./deps.nix;
}
