# How to add an override

To override records for external domains, in the server section add something like this:

```
server:
    # domain.com override
    local-data: "www.domain.com. 60 IN A 1.2.3.4"
    local-data: "landing.domain.com. 60 IN CNAME proxy-0123456789.us-east-1.elb.amazonaws.com."
    local-zone: "domain.com." transparent
```
