+++
date = "2021-01-14T22:04:00Z"
title = "Pebble and lego to test ACME with NixOS"
description = "Configuring lego to use Pebble as an ACME server on NixOS"
+++

When configuring a new service I want to run on NixOS, I often use
[nixos-shell][nixos-shell] to quickly standup a temporary VM locally with my new
configuration. When this configuration is a service, I often want to ensure I
have TLS configured properly, including the correct permissions on the
certificate and key files managed by [lego][lego].

[nixos-shell]: https://github.com/Mic92/nixos-shell
[lego]: https://go-acme.github.io/lego/

However, I don't neccessarily want to send unacceptable amounts of traffic to
production ACME servers, or deal with proper validation with their staging
services. Fortunately, we can configure the NixOS VM to start a testing ACME
server, [Pebble][pebble], and configure Lego to use it.

[pebble]: https://github.com/letsencrypt/pebble

## Pebble

Pebble is a small, single-binary ACME server intended for testing. Keys and
certificates are randomnized between calls, but this is fine for an emphermial
VM.

First, we'll want to configure Pebble to start, which we can do with the
`systemd.service` NixOS option. I use the `toJSON` builtin function to create a
JSON configuration file for Pebble from a Nix attribute set. I also reference
the default certificate and key from the source package, as they are not yet
copied to the output package.

```nix
{ pkgs }:

let
  pebbleConfig = pkgs.writeText "pebble.json" (builtins.toJSON {
    pebble = {
      listenAddress = "0.0.0.0:14000";
      managementListenAddress = "0.0.0.0:15000";
      certificate = "${pkgs.pebble.src}/test/certs/localhost/cert.pem";
      privateKey = "${pkgs.pebble.src}/test/certs/localhost/key.pem";
      httpPort = 5002;
      tlsPort = 5001;
      ocspResponderURL = "";
      externalAccountBindingRequired = false;
    };
  });
in {
  systemd.services.pebble = {
    description = "Pebble ACME Test Server";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Environment = [ "PEBBLE_VA_NOSLEEP=1" "PEBBLE_VA_ALWAYS_VALID=1" ];
      ExecStart = "${pkgs.pebble}/bin/pebble -config ${pebbleConfig}";
      DynamicUser = true;
    };
  };
}
```

You can modify some behavior of Pebble through environment variables. I set two
for better behavior in a development VM:

* `PEBBLE_VA_NOSLEEP` disables any artifical sleeps in the issuance path, as
  we're not interested in testing lego's validationg polling.
* `PEBBLE_VA_ALWAYS_VALID` disables all validation methods, and assumes domains
  have already been successfully validated.

One warning from the Pebble documentation bares repeating here:

> Pebble is **NOT INTENDED FOR PRODUCTION USE**. Pebble is for **testing only**.

## lego

lego is a widely used ACME client that implements all of the ACME challenges,
bindings for major DNS providers, and support for bundling certificates. It's
used as the implementation to NixOS's `security.acme` options. This means most
of the configuration is already done for us.

```nix
{
  security.acme = {
    server = "https://localhost:14000/dir";
    acceptTerms = true;
    email = "webmaster@example.com";
    certs = {
      "example.com" = {
        webroot = "/var/www/example.com";
        group = "prosody";
      };
    };
  };
}
```

Despite not needing to implement any challenges, as we've disabled them in
Pebble, we still need to provide `webroot` configuration. The `group` attribute
is used to set the group permission on the generated certificates and keys, and
should be set to the same user your server is running as.

There's one farther complication: lego does not trust the certificate authority
used by the ACME server, and thus it won't issue requests out of the box. We can
configure the lego to trust these certificates by setting the environment of the
generated service unit.

```nix
{
  systemd.services."acme-example.com".serviceConfig.Environment = [
    "LEGO_CA_CERTIFICATES=${pkgs.pebble.src}/test/certs/pebble.minica.pem"
    "LEGO_CA_SERVER_NAME=localhost"
  ];
}
```

## Usage

The certificates and keys created by `security.acme` are stored underneath
`/var/lib/acme/`. This can be provided to your server's configuration.

```nix
{
  services.prosody = {
    enable = true;
    virtualHosts."example.com" = {
      enabled = true;
      ssl.cert = "/var/lib/acme/git.terinstock.com/fullchain.pem";
      ssl.key = "/var/lib/acme/git.terinstock.com/key.pem";
    };
  };
}
```
