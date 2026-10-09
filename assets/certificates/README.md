# NTUT GeoServer intermediate certificate

`twca_ssl_2023.pem` is TWCA's public SSL intermediate certificate, downloaded
over validated HTTPS from
https://sslserver.twca.com.tw/cacert/Cyber_SSL_2023.crt on 2026-10-09 and converted
from DER to PEM. Its SHA-256 fingerprint is:

```text
01af2324d098098f5e0cdf6faabada430b21cce777f47eacb26248b2fda3e531
```

It expires on 2033-02-23. NTUT's GeoServer omits this certificate from its TLS
chain. The desktop map client adds this intermediate to a dedicated
`SecurityContext(withTrustedRoots: true)`; hostname and certificate validation
remain enabled. Android and iOS use the existing native HTTP adapter and the
platform's certificate validation. No `badCertificateCallback` is installed.

Review the certificate if the server's issuing CA changes. Remove this asset and
the desktop augmentation when the server reliably supplies the complete chain.
