$ORIGIN .

...

                            IN      CAA  0 issue "letsencrypt.org"
                            IN      CAA  0 iodef "mailto:hostmaster@example.com"

_acme-challenge             IN      NS ns.example.com.


# If generating letsencrypt keys for subdomains, you can add CNAME records
# to use _acme-challenge.example.com domain for validation
_acme-challenge.subdomain1  IN      CNAME   _acme-challenge.example.com.
_acme-challenge.subdomain2  IN      CNAME   _acme-challenge.example.com.

....
