{ pkgs ? import ./nix/pkgs.nix { }, ... }:

let d = import ./default.nix { inherit pkgs; };

in pkgs.mkShell { buildInputs = [ d.hugo ]; }
