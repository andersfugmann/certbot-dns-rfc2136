$ORIGIN .
$TTL 3600	; 1 hour
_acme-challenge.example.com IN SOA ns.example.com. hostmaster.example.com. (
    2023010101 ; serial
    1          ; refresh (1 second)
    1          ; retry (1 second)
    1          ; expire (1 second)
    1          ; minimum (1 second)
)
        NS	ns.example.com.
