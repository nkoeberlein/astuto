# Test directory for LDAP specs

`spec/models/ldap_config_spec.rb` runs its directory examples only with `LDAP_TEST_HOST` set.
With OpenLDAP installed (`apt-get install slapd ldap-utils`):

```bash
mkdir -p /tmp/astuto-ldap/data && slapd -f spec/fixtures/ldap/slapd.conf -h ldap://127.0.0.1:3890/
```

```bash
ldapadd -x -H ldap://127.0.0.1:3890 -D cn=admin,dc=example,dc=com -w adminsecret -f spec/fixtures/ldap/test-directory.ldif
```

```bash
LDAP_TEST_HOST=127.0.0.1 LDAP_TEST_PORT=3890 bundle exec rspec spec/models/ldap_config_spec.rb
```

Entries: service account `cn=service,ou=people,dc=example,dc=com` / `servicesecret` (the only one
allowed to search), `uid=ada` / `adasecret`, `uid=bob` / `bobsecret`. Test passwords only.
