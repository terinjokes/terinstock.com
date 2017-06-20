+++
date = "2014-07-02T00:00:00Z"
title = "TLS with Erlang"
aliases = [
  "/blog/2014/07/02/tls-with-erlang.html"
]
+++

I recently configured an HTTP server written in Erlang for secure communication with Transport Layer Security (TLS), successor to Secure Sockets Layer (SSL). Unfortunately, my attempt resulted in TLS errors from both browsers and command line tools.  Determined to find a solution, I dug into the HTTP server and Erlang's SSL library to resolve these TLS connection failures.

In the process I uncovered issues with intermediate bundles and elliptic curve selections, as well as a configuration optimization.

## Bundling Intermediate Certificates

When you buy a certificate for your site, you're likely to also receive an intermediate bundle. This intermediate bundle is a chain of certificates that bind the certificate issued for your site to a trusted certificate located on the user's computer or browser (a "root certificate"). If this bundle is excluded, the browser won't trust the connection, since it can't verify each link of the chain.

The issuer reminds you to add this bundle to your server's configuration—it is important not to forget this step! Erlang's SSL library can be configured to include the intermediate bundle by providing the path to the `cacertfile` option.

```erlang
ssl:start().
{ok, ListenSocket} = ssl:listen(443, [
    {certfile, "/full/path/to/server_cert.pem"},
    {keyfile, "/full/path/to/server_key.pem"},
    {cacertfile, "/full/path/to/bundle.pem"}
  ]).
ssl:transport_accept(ListenSocket).
```

Erlang will now send the entire certificate chain to the browser during the connection, and the browser can trust the connection.

## Ode to Debugging TLS

At this point, I expected to be done. Unfortunately, while OpenSSL and TLS scanning tools such as [sslyze](https://github.com/iSECPartners/sslyze) would connect fine, my copies of Chrome, Firefox, and curl refused to connect with cryptic SSL errors such as `ERR_SSL_CLIENT_AUTH_SIGNATURE_FAILED` and `sec_error_invalid_key`. Chrome's debugging logs provided no additional information.

### TLS Handshakes: A Primer

To start a connection to a secure site, the client and browser must first configure the secure connection in a process commonly called a "TLS Handshake".

In a full handshake, two roundtrips between the browser and the server are required:

* The browser sends a `ClientHello` message to the server.

  This message includes the highest TLS version supported, lists of supported cipher suites and compression algorithms, and other TLS extensions, including a list of known named elliptic curves.

* The server responds with `ServerHello`, `Certificate`, an optional `ServerKeyExchange` message, and `ServerHelloDone` messages.

  The `ServerHello` message details specific options used for the connections including the TLS version, the cipher suite, the compression algorithm, and any additional TLS extensions. The TLS version should be the highest version support by both client and server. The server maintains a priority list for cipher suites and compression algorithms, and it selects the highest priority supported by the browser.

  The server then attaches the entire certificate chain in a `Certificate` message, so the browser can verify the authenticity of the connection.

  If the `Certificate` message doesn't contain enough information to allow a client to exchange a session key, such as with a Diffie–Hellman key exchange, then a `ServerKeyExchange` message is included.

  The server then ends with `ServerHelloDone`.

* The client responds with a `ClientKeyExchange`, `ChangeCipherSpec` and `Finished` messages.

  The `ClientKeyExchange` message contains a secret key determined by both sides using public key encryption. The specifics of how the session key is generated is outside the scope of this primer.

  With the `ChangeCipherSpec` message, the browser tells the server to switch to encrypted communication for the rest of the communication.

  To verify the integrity of the communications up to this point, a hash of the previous messages is taken and sent as part of the `Finished` message. The server will also compute a hash over the same messages and compare.

* Finally, the server sends `ChangeCipherSpec` and `Finished` messages.

  The server verifies the hash sent in the client's `Finished` message, then acknowledges the encryption communications and finishes, sending a similar hash to the client.

### The Failed TLS Handshake

Interested in understanding the exact exchange between my browser and the server, I logged the TLS traffic with the network protocol analyzer Wireshark. The browser and the server successfully exchanged `ClientHello`, `ServerHello`, `Certificate`, `ServerKeyExchange`, and `ServerHelloDone` messages before the browser unexpectedly closed the connection.

Inspecting the `ServerHello` message informed me the server agreed on using TLS 1.2 and choose the `TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA` cipher suite. Both supported by the browser.

From [RFC4492](http://tools.ietf.org/rfc/rfc4492.txt), when the `ECDHE_ECDSA`, `ECDHE_RSA`, or `ECDH_anon` ciphers are chosen, a `ServerKeyExchange` message is sent containing the ECDHE public key used to derive the shared key.

The `ServerKeyExchange` portion of the TLS handshake from the server to the client is replicated below.

```text
0000   0c 00 01 49 03 00 16 41 04 b2 33 23 71 c9 da 80
0010   94 d3 ec eb 05 9f e5 36 91 a7 e2 e5 40 78 aa 03
0020   38 4f eb 7c 36 1b 92 21 58 cf c3 e5 b7 08 40 5a
0030   6a eb d2 6a 22 90 e0 47 28 ce 70 9b bb 87 17 d3
0040   4a bc 7c 78 14 ef 97 0d 0d 02 01 01 00 91 7e 3c
0050   ce 9f 06 1d 00 47 4f 53 85 df 2e 04 31 9a 14 a3
0060   25 bd 51 b3 1a 0f dd 3b c3 f4 25 b0 23 d5 34 0a
0070   a3 fc 2a e2 08 34 29 87 00 91 0e 10 6a 40 b3 b5
0080   61 0c 77 9a 8a 0c 50 dc 78 57 ab 2a 51 66 d0 0d
0090   b7 3c 4d c0 28 b9 06 b4 f5 f6 48 f6 5a 02 c2 7e
00a0   8f b2 ac 4b 03 3a 40 c0 e2 c6 2f 77 61 58 ea 0d
00b0   ab 6c 7f 57 be e1 03 0b c6 1e 2a b0 67 ab c2 db
00c0   0a 5b c4 ab 51 9a 76 e6 75 2d e6 ca ce 06 4b f5
00d0   8f dc f0 c1 42 65 14 c0 79 80 51 f2 68 3b 4a 51
00e0   0d 50 5a 01 32 e3 5c 8d cd 8c ec c1 c4 fa 84 3a
00f0   33 37 4c 9d d5 54 f9 6c aa b8 27 27 7b 4a 7c 33
0100   27 8e 48 48 33 87 73 11 9b 92 0b e3 99 49 23 7b
0110   c5 ab 53 ef f2 86 df 56 e5 97 6b 2d 93 5f c0 8a
0120   e6 68 4f 6b 3a 1b 55 26 08 aa c0 36 74 21 ed cc
0130   0e c9 22 0b 97 51 c1 01 48 3f 01 d2 74 fe 36 18
0140   5f 5c 91 47 b3 19 1c 00 69 7f 17 1b c3
```

* `0c` indicates this message is a `ServerKeyExchange` message
* `00 01 49` is the length of 0x000149 (in decimal, 329) bytes
* `03` is the elliptic curve type, in this case "named_curve"
* `00 16` is the named curve, `secp256k1`
* The ECDHE public key and signature follows.

At this point the browser verifies the signature and retrieves the elliptic curve parameters and ECDHE public key from the `ServerKeyExchange` message.

Section 5.4 of RFC4492 ends with the following note:

> A possible reason for a fatal handshake failure is that the client's capabilities for handling elliptic curves and point formats are exceeded

While Erlang supports all 25 elliptic curves named in RFC4492, common browsers only support a smaller subset of two or three.[^curves-support] In the above snippet, we see that Erlang chose `secp256k1`, the elliptic curve used in [Bitcoin](https://en.bitcoin.it/wiki/Secp256k1), and not one supported by my browsers.

[^curves-support]: **Edit:** An earlier version of this post claimed browsers only supported three elliptic curves: `secp192r1`, `secp224r1`, and `secp256r1`. This information was incorrectly included from an earlier draft.

Erlang's early support of elliptic curves are problematic. When picking an elliptic curve, Erlang does not consider the list of supported curves sent by the browser. This has been resolved with the [Erlang R16R03-1](http://www.erlang.org/download_release/23) release.

## Configuration of TLS and Ciphers

Erlang's SSL library has defaults for the TLS versions, cipher suites and renegotiation behavior. You may want to change these options for client compatibility and for resiliency to TLS attacks.

```erlang
ssl:start().
{ok, ListenSocket} = ssl:listen(443, [
    {server_renegotiate, true},
    {versions: [ "tlsv1.1", "tlsv1.2" ]},
    {ciphers: [ "ECDHE-ECDSA-AES128-SHA256", "ECDHE-ECDSA-AES128-SHA" ]}
  ]).
ssl:transport_accept(ListenSocket).
```

[CloudFlare publishes](https://support.cloudflare.com/hc/en-us/articles/200933580) the cipher suites they use with nginx. You can check the ciphers supported by your Erlang installation by running the following in a `erl` session.

```erlang
rp(ssl:cipher_suites(openssl)).
```

I created [a patch](https://git-wip-us.apache.org/repos/asf?p=couchdb.git;a=commit;h=fdb2188) for CouchDB that adds the configuration options `secure_renegotiate`, `ciphers`, and `tls_versions` to the SSL section:[^couchdb-patch]

[^couchdb-patch]: **Edit:** My patch did not land in CouchDB 1.6.0. CouchDB has since been reorganized into multiple repos, but my patch continues to be in place for a future stable release.

```ini
[ssl]
certfile           = /full/path/to/server_cert.pem
keyfile            = /full/path/to/server_key.pem
cacertfile         = /full/path/tp/bundle.pem
secure_renegotiate = true
tls_versions       = [ "tlsv1.1", "tlsv1.2" ]
ciphers            = [ "ECDHE-ECDSA-AES128-SHA256", "ECDHE-ECDSA-AES128-SHA" ]
```

---

While presented through the lens of an HTTP server in Erlang, the same basic steps could be extrapolated to any secure server written in any language. Recapping my debugging process: First, I ensured the server is configured to send the entire certificate chain to the client. Then, I tested the connection with a TLS scanner or a network protocol analyzer. Finally, once the server is properly communicating, I took a look at my server's TLS configuration to ensure it is secure and reflect current best practices.
