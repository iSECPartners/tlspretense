CertMaker
=========

Ruby code to generate a variety of SSL certificates for testing certificate
validation.

Description
-----------

CertMaker provides tools for building and managing certificates that vary from
each other in only slightly different ways. The CertificateFactory class makes
it easier to create a variety of similar certificates. It can be configured to
generate a particular certificate, then that configuration can be overridden
when a certificate is created.

Additionally, CertificateGenerator is a class that provides the ability to
generate a suite of certificates from a hash configuration.

To see a sample use of this code, you can run:

    rake certs:ssl
    
From the project's base directory. It loads the config.yml file and pulls the
certificate details out of the 'certs' key. Additionally, the task will write
the various certificates into the `cert` directory.

TODO
----

* Add more support for subjectAltName. Eg, testing whether the hostname is in
  it or not, null name there, etc.
* truly unique serial numbers for a given CA. Alternatively, we could use the
  first cert's serial as a starting point and increment from there.
* Allow the user to configure a premade CA as the good CA.

