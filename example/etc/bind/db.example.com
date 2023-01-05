# Bind9 DNS zone snippet for parent zone 'example.com'. 
# This zone does not serve the DNS verification, but 
# redirects all requests to the domain '_acme-challenge.subdomain1.example.com.', which
# can be served from a different DNS server. 

...

example.com.   IN      CAA  0 issue "letsencrypt.org"
example.com.   IN      CAA  0 iodef "mailto:hostmaster@example.com"

# Indicate that 'ns.example.com' is responsible for answering queries for the domain 
# _acme-challenge.example.com. This is usefull is you are using a DNS hosting environment 
# which does not allow for fast DNS updates. You can then point to a local DNS server 
# (e.g. bind9) to serve DNS requests for the _acme-challenge.example.com domain.

# DNS update requests for _acme-challenge.example.com will be sent to 'local_ns.example.com', unless 
# a specific server is given in the configuration file (dns_rfc2136_server option)


_acme-challenge.example.com.             IN      NS local_ns.example.com.
local_ns.example.com.                    IN      A  1.2.3.4
local_ns.example.com.                    IN      AAAA  1:2:3:4::5

# To generate letsencrypt certificates for subdomains, you can add CNAME records
# to redirect verification to use '_acme-challenge.example.com' domain.
# In this example verification for domain 'example.com' 'subdomain1.example.com' 
# and 'subdomain2.example.com' is handled by `_acme-challenge.example.com` domain.

_acme-challenge.subdomain1.example.com.  IN      CNAME   _acme-challenge.example.com.
_acme-challenge.subdomain2.example.com.  IN      CNAME   _acme-challenge.example.com.

....
