# Certbot-dns-rfc2136
This repository contains a helper script for dynamically updating
dns entries needed to verify certbot/letsencrypt certificates using [`dns-01`](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) challenges.
`Dns-01` challenges allow creation of wildcard letsencrypt certificates.

The problem using DNS to verify domain authority is that it takes time
for the records to propagate. To solve this problem you can delegate
the all keys to be inserted in a different domain under your control
and insert needed TXT records in this domain (potentially served by a
local version of bind).

# Features
* Drop in replacement the certbot `dns-rfc2136-plugin`
* Handles `CNAME` domain delegation (allows using a different zone for letsencrypt verification)
* Uses dynamic updates using `nsupdate` (rfc 2136)
* Batches dns updates to reduce number of serial changes
* Follows `NS` DNS records unless nsupdate server is specified explicitly

# Installation
Copy the script `certbot-dns-rfc2136` to `/usr/local/bin`

```bash
sudo install  ./certbot-dns-rfc2136 /usr/local/bin
```

The following assumes you already installed certbot
## Dependencies
* certbot
* bind9-host
* bind9-dnsutils
* bash

```bash
apt install certbot bind9-host bind9-dnsutils bash
```

# Setup
For the certificates you want to update using this plugin, update
the configuration files in `/etc/letsencrypt/renewal` to contain the
following entries under the section `renewalparams`

```inifile
[renewalparams]
account = ...
aserver = ...
authenticator = manual
manual_auth_hook = /usr/local/bin/certbot-dns-rfc2136 auth
manual_cleanup_hook = /usr/local/bin/certbot-dns-rfc2136 cleanup
pref_challs = dns-01,
```

Create or update the file `/etc/letsencrypt/rfc2136-credentials.ini`
to contain information on how to apply dns updates.

```inifile
dns_rfc2136_server = <name of the server to issue nsupdate against>
dns_rfc2136_port = <server port - usually 53>
dns_rfc2136_name = <name of the key used for nsupdates>
dns_rfc2136_secret = <secret associated with the key used>
dns_rfc2136_algorithm = <key algorithm>
dns_rfc2136_propagation_time = <time in seconds for dns propagation>
```

## Example
In the following example, we want to verify ownership of the domain `example.com` to create/renew a certificate

First create a key to be used for dns updates:

```bash
$ rndc-confgen -A hmac-sha512 -k certbot

key "certbot" {
	algorithm hmac-sha512;
	secret "mMrpRENVlakYKHXXyygYrwvo+3sfzX9vIuk60PnL15vmqCWhxJwsVxLAJlAV47bu+sY13Xs7BuLoKVwcILzbCA==";
};
...

```

Now create or update the configuration file for `certbot-dns-rfc2136` as [`/etc/letsencrypt/rfc2136-credentials.ini`](https://github.com/andersfugmann/certbot-dns-rfc2136/blob/main/example/etc/letsencrypt/rfc2136-credentials.ini)

```inifile
dns_rfc2136_server = 127.0.0.1
dns_rfc2136_port = 53
dns_rfc2136_name = certbot-key
dns_rfc2136_secret = mMrpRENVlakYKHXXyygYrwvo+3sfzX9vIuk60PnL15vmqCWhxJwsVxLAJlAV47bu+sY13Xs7BuLoKVwcILzbCA==
dns_rfc2136_algorithm = HMAC-SHA512
dns_rfc2136_propagation_time = 1
```

And update the renew parameters in [`/etc/letsencrypt/renew/example.com.conf`](https://github.com/andersfugmann/certbot-dns-rfc2136/blob/main/example/etc/letsencrypt/renew/example.com.conf):

```inifile
# renew_before_expiry = 30 days
version = 2.1.0
archive_dir = /etc/letsencrypt/archive/example.com
cert = /etc/letsencrypt/live/example.com/cert.pem
privkey = /etc/letsencrypt/live/example.com/privkey.pem
chain = /etc/letsencrypt/live/example.com/chain.pem
fullchain = /etc/letsencrypt/live/example.com/fullchain.pem

# Options used in the renewal process
[renewalparams]
account = 0123456789abcdef0123456789abcdef
server = https://acme-v02.api.letsencrypt.org/directory
key_type = rsa
authenticator = manual
manual_auth_hook = /usr/local/bin/certbot-dns-rfc2136 auth
manual_cleanup_hook = /usr/local/bin/certbot-dns-rfc2136 cleanup
pref_challs = dns-01,
```
(it has to be `dns-01,`, even if the comma looks like a typo)

## Configure bind9
Based on the output from `rndc-confgen -A hmac-sha512 -k certbot` take
a look at the files and snippets under
[`./example`](https://github.com/andersfugmann/certbot-dns-rfc2136/blob/main/example),
and
[`./example/etc/bind`](https://github.com/andersfugmann/certbot-dns-rfc2136/blob/main/example/etc/bind)
in particular.
