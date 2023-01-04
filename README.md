# Certbot-dns-rfc2136
This repository contains a helper script for dynamically updating
dns entries needed to verify certbot/letsencrypt certificates.

## Features
* Handles `CNAME` records correctly
* Uses dynamic updates using `nsupdate` (rfc 2136)
* Batches updates (reduce number of serial changes)
* Drop in replacement the certbot `dns-rfc2136 plugin` 
* Handles `CNAME` domain redirects (allows using a different zone for letsencrypt verification) 

# Installation
Copy the script `certbot-dns-rfc2136.sh` to `/usr/local/bin`

```bash
sudo install  ./certbot-dns-rfc2136.sh /usr/local/bin
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

## Setup
For the certificates you want to update using this plugin, update
the configuration files in `/etc/letsencrypt/renewal` to contain the
following entries under the section `renewalparams`

```inifile
[renewalparams]
account = ...
aserver = ...
authenticator = manual
manual_auth_hook = /usr/local/bin/certbot-dns-rfc2136.sh auth
manual_cleanup_hook = /usr/local/bin/certbot-dns-rfc2136.sh cleanup
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
dns_rfc2136_propergation_time = <time in seconds for dns propergation>
```

### Example:
In the following example, we want to verify ownership of the domain `example.com` to create/renew a certificate

```bash
$ rndc-confgen -A hmac-sha512 -k certbot

key "certbot" {
	algorithm hmac-sha512;
	secret "mMrpRENVlakYKHXXyygYrwvo+3sfzX9vIuk60PnL15vmqCWhxJwsVxLAJlAV47bu+sY13Xs7BuLoKVwcILzbCA==";
};
```

Based on this, we construct [`/etc/letsencrypt/rfc2136-credentials.ini`](https://github.com/andersfugmann/certbot-dns-rfc2136/blob/main/example/etc/letsencrypt/rfc2136-credentials.ini)

And update the renew parameters in [`/etc/letsencrypt/renew/example.com`](https://github.com/andersfugmann/certbot-dns-rfc2136/blob/main/exampleletsencrypt/renew/example.com)

## Configure bind9
Based on the output from `rndc-confgen -A hmac-sha512 -k certbot` take
a look at the files and snippets under [`./example`](https://github.com/andersfugmann/certbot-dns-rfc2136/blob/main/example), and [`./example/etc/bind`](https://github.com/andersfugmann/certbot-dns-rfc2136/blob/main/example/etc/bind) in particular.

