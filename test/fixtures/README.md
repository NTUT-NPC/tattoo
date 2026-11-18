# HTML fixtures

This directory contains de-identified NTUT HTML/XML responses used as parser test fixtures and development references. The fixture body keeps the original DOM structure, attributes, status text, and other parser anchors while personal, authentication, and academic-private values are replaced with realistic fake data.

Fixtures are grouped by NTUT service. Filenames use the page name, a three-digit serial, and a short description of the captured state:

```text
<page>_<serial>_<state>.html
```

Raw captures belong in `tmp/html_snapshot/` only. Before promoting a capture, review the metadata, hidden fields, scripts, comments, URLs, and visible tables; remove the raw-capture warning; write a meaningful English `message`; and sweep the entire file for original sensitive values. Do not commit credentials, cookies, session tickets, OAuth codes, or unsanitized captures.
