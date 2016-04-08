{%- from "salt/map.jinja" import minion with context %}
{%- if minion.enabled %}

include:
- salt.minion.service

/etc/salt/minion.d/_signing_policies.conf:
  file.managed:
  - source: salt://salt/files/_signing_policies.conf
  - template: jinja
  - require:
    - pkg: salt_minion_packages
  - watch_in:
    - service: salt_minion_service

{%- for ca_name,ca in minion.ca.iteritems() %}

/etc/pki/ca/{{ ca_name }}/certs:
  file.directory:
  - makedirs: true

/etc/pki/ca/{{ ca_name }}/ca.key:
  x509.private_key_managed:
  - bits: 4096
  - backup: True
  - require:
    - file: /etc/pki/ca/{{ ca_name }}/certs

/etc/pki/ca/{{ ca_name }}/ca.crt:
  x509.certificate_managed:
  - signing_private_key: /etc/pki/ca/{{ ca_name }}/ca.key
  - CN: {{ ca.common_name }}
  - C: {{ ca.country }}
  - ST: {{ ca.state }}
  - L: {{ ca.locality }}
  - basicConstraints: "critical CA:true"
  - keyUsage: "critical cRLSign, keyCertSign"
  - subjectKeyIdentifier: hash
  - authorityKeyIdentifier: keyid,issuer:always
  - days_valid: {{ ca.days_valid.authority }}
  - days_remaining: 0
  - backup: True
  - require:
    - x509: /etc/pki/ca/{{ ca_name }}/ca.key

mine.send:
  module.run:
  - func: x509.get_pem_entries
  - kwargs:
      glob_path: /etc/pki/ca/{{ ca_name }}/ca.crt
  - onchanges:
    - x509: /etc/pki/ca/{{ ca_name }}/ca.crt

{%- endfor %}

{%- endif %}