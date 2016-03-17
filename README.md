# nss_tools-cookbook

This cookbook provides a LWRP for managing Mozilla NSS Certificate databaes.

## Syntax

A **nss_tools_certdb** resource block manages a named entry in a Mozilla Certificate
database.  The full syntax for all of the properties that are available to the
**nss_tools_certdb**:
```ruby
nss_tools_certdb 'name' do
  ca            String, Array
  crt           String
  dbprefix      String
  der           String
  directory     String
  key           String
  name          String
  notifies      # see description
  subscribes    # see description
  action        Symbol # defaults to :update
end
```
where
* `name` is the name of the entry in the database (-n)
* `directory` is the directory of the database (-d), default: `$HOME/.netscape`
* `dbprefix` is the prefix of the database (see certutil for more info), optional
* `ca`, `crt`, `der`, `key`: see "Properties" section below

## Actions

This resource has the following actions:

* `:update` Default.  Adds a new entry or checks to see if it is up-to-date with
the source.
* `:delete` Ensures that an entry doesn't exist.
* `:nothing` Define this resource block to do nothing until notified by another
resource to take action. When this resource is notified, this resource block is
either run immediately or it is queued up to be run at the end of the
chef-client run.

## Properties

This resource has different properties depending on the input type.  Input can
be certificate / key pairs in PEM or DER format.  If both are passed PEM will
take priority.

### PEM Certificate + Key (optionally CA)

* `ca` (**String**, **Array**) (Optional): Path to a PEM encoded CA certificate
or CA certificate bundle.  Can also be an array of paths.
* `crt` (**String**): Path to a PEM encoded certificate.
* `key` (**String**): Path to a PEM encoded private key.

#### Example
```ruby
nss_tools_certdb 'My Certificate' do
  directory   '/etc/myapp'
  dbprefix    'myapp'
  ca          '/etc/ssl/ca/my-ca.crt'
  crt         '/etc/ssl/cert/my-cert.crt'
  key         '/etc/ssl/private/my-cert.key'
  notifies    :restart, 'service[myapp]', :delayed
end
```

### DER (PKCS12)

* `der` (**String**): Path to PKCS12 DER encoded certificate / key (optionally
CA) file.

#### Example
```ruby
nss_tools_certdb 'My Certificate' do
  directory   '/etc/myapp'
  dbprefix    'myapp'
  der         '/etc/ssl/my-cert.p12'
  notifies    :restart, 'service[myapp]', :delayed
end
```

## License and Authors

Author:: Altiscale, Inc (<travis@altiscale.com>)

License:: Apache 2.0
