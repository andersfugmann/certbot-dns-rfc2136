# Certbot-dns-rfc2136
This repository contains a helper script for dynamically updating
dns entries needed to verify certbot/letsencrypt certificates.

## Features
* Handles `CNAME` records correctly
* Uses dynamic updates using `nsupdate`
* Batches updates (reduce number of serial changes)
* Drop in replacement the RFC 2136 DNS plugin for Certbot

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
```bash
$ rndc-confgen -A hmac-sha512 -k certbot

key "certbot" {
	algorithm hmac-sha512;
	secret "mMrpRENVlakYKHXXyygYrwvo+3sfzX9vIuk60PnL15vmqCWhxJwsVxLAJlAV47bu+sY13Xs7BuLoKVwcILzbCA==";
};

options {
	default-key "certbot-key";
	default-server 127.0.0.1;
	default-port 953;
};
# End of rndc.conf

# Use with the following in named.conf, adjusting the allow list as needed:
# key "certbot-key" {
# 	algorithm hmac-sha512;
# 	secret "mMrpRENVlakYKHXXyygYrwvo+3sfzX9vIuk60PnL15vmqCWhxJwsVxLAJlAV47bu+sY13Xs7BuLoKVwcILzbCA==";
# };
#
# controls {
# 	inet 127.0.0.1 port 953
# 		allow { 127.0.0.1; } keys { "certbot-key"; };
# };
# End of named.conf
```

From this info, we construct /etc/letsencrypt/rfc2136-credentials.ini
```inifile
# Target DNS server
dns_rfc2136_server = 127.0.0.1
# Target DNS port
dns_rfc2136_port = 953
# TSIG key name
dns_rfc2136_name = certbot-key
# TSIG key secret
dns_rfc2136_secret = mMrpRENVlakYKHXXyygYrwvo+3sfzX9vIuk60PnL15vmqCWhxJwsVxLAJlAV47bu+sY13Xs7BuLoKVwcILzbCA==
# TSIG key algorithm
dns_rfc2136_algorithm = HMAC-SHA512
# As we are using our own local server, assume that dns update are almost instant
dns_rfc2136_propagation_time = 1


```

## Configure bind9
In the following, the domain `example.com` is assumed to be configured
in bind9 running locally.

Copy the zone `db._acme-challenge.example.com` to `/etc/bind/`
Add the following lines to `/etc/bind/named.conf.local`


key "certbot-key" {
  algorithm hmac-sha512;
  secret "mMrpRENVlakYKHXXyygYrwvo+3sfzX9vIuk60PnL15vmqCWhxJwsVxLAJlAV47bu+sY13Xs7BuLoKVwcILzbCA==";
};
