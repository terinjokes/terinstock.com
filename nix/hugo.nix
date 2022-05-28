{ lib, buildGo118Module, fetchFromGitHub, installShellFiles, ... }:

buildGo118Module rec {
  pname = "hugo";
  version = "0.99.1";

  src = fetchFromGitHub {
    owner = "gohugoio";
    repo = "hugo";
    rev = "v${version}";
    sha256 = "0wn8lkb7xkdlbnbj9rn16x1glj11m0j4a3db6c96n1iihnxifnrl";
  };

  tags = [ "extended" ];
  proxyVendor = true;
  subPackages = [ "." ];

  vendorSha256 = "0n3f8n36pr0l8c497qrg4d21py0rhhk0mbgwm56yfapd33q2smq3";
  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    $out/bin/hugo gen man
    installManPage man/*
    installShellCompletion --cmd hugo \
      --bash <($out/bin/hugo gen autocomplete --type=bash) \
      --fish <($out/bin/hugo gen autocomplete --type=fish) \
      --zsh <($out/bin/hugo gen autocomplete --type=zsh)
  '';
}
