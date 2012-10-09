SSL Client Testing
==================

A Set of tools for testing an SSL client's certificate validation.


Description
-----------

Ssl\_client\_testing provides a set of tools to test SSL certificate
validation. It currently provides two sets of libraries for this purpose:

* *CertMaker*, which generates SSL certificates with a variety of flaws
* *SSLTest*, a framework for running tests using various certificate chains.


CertMaker
=========

CertMaker provides tools for building and managing certificates, especially
certificates that vary from each other in only slightly different ways. It is
currently run through the project's Rakefile:

    rake certs:ssl

This task uses certificate descriptions in config.yml to generate certificates
and unencrypted private keys for each described certificate. It can generate
the entire set of certificates from scratch, or it can use an existing CA
instead of generating a new _goodca_. Read over the comments in the _certmaker_
and the _certs_ sections of config.yml.

WARNING: Running this task a second time will regenerate all of the
certificates in the _certs_ directory! If you are not using an existing CA and
wish to regenerate the certificates, you will wind up with a new set of
certificates based around a CA that uses a new public key.

Internally, the CertificateFactory class makes it easier to create X509
certificates from Hashes (and thus YAML or other config data). It also makes it
easy to generate several similar certificates that are all based off the same
basic certificate. Additionally, CertificateGenerator is a class that provides
the ability to generate a suite of certificates from a Hash configuration, such
as the one in config.yml.


SSLTest
=======

SSLTest provides a test harness for testing SSL certificate validation. It runs
on a system placed between the SSL/TLS client to-be-tested and the local
network's gateway, much like how Mallory proxy works, which allows it to
intercept the desired traffic without having to deal with client-side proxy
settings. It then presents an X509 certificate chain to the client, and it uses
whether or not the TLS handshake completes to determine whether the client
accepted or rejected the certificate chain.

The test harness anticipates working with a client that may connect to more
than one host. The config.yml file specifies a hostname that should be used for
the actual test where the current test certificate chain is presented to the
client --- all other intercepted SSL connections are essentially ignored
(although they currently have their certificate re-signed by the goodca in
order to make interception easier).

TODO: Usage

Requirements
------------

Obviously, this framework requires a certain amount of setup, and it has some
requirements:

* Ruby 1.9.x is needed for full Server Name Indicatio (SNI) support. It must
  also be built against a version of OpenSSL that has SNI fully enabled. Ruby
  1.8.7 supports the SNI callback on the server-side of an SSL connection, but
  Ruby 1.8.7's version of the OpenSSL extension does not have a way for clients
  to request an SNI hostname.

* PacketThief, which is used for intercepting packeets, currently requires the
  NetFilter or IPFW firewalls. In other words Linux, MacOSX 10.6, or BSD with
  IPFW. (PF support forthcoming)

* The test runner needs to be run as root in order to manipulate the
  firewall, such as with `sudo`.

* The SSLTest system needs to be able to intercept the client's network
  traffic. A common setup for doing this when testing mobile code is to plug
  your laptop into an ethernet connection that has access to the server that
  the client would normally connect to, and to then bridge or NAT your wifi
  interface.

* You need to make the SSL client trust the _goodca_ CA certificate. You can
  either generate a new goodca and install it in the client's trust store, or
  you can use an existing test CA to generate the test certificates.

Limitations
-----------

* The Server Name Indication (SNI) TLS extension does not have full support in
  Ruby 1.8.7.

* Protocols that explicitly call STARTTLS to enable SSL/TLS (eg, SMTP and IMAP)
  are not yet supported. They would require protocol-specific support. The
  version of these protocols where they are wrapped in SSL should be testable
  though.

* It currently uses the goodca to re-sign certificates from hostnames that do
  not match the configured test hostname.

TODO
----

* Differentiate generating goodca from the rest of the certificates.

* Add more support for subjectAltName. Eg, testing whether the hostname is in
  it or not, null name there, etc.

* truly unique serial numbers for a given CA. Alternatively, we could use the
  first cert's serial as a starting point and increment from there.

* Build certs and chains of certs for each test so that something like
  s\_server could use them.

* Document how to run SSLTest from MacOSX

* Document how to run SSLTest from a Linux VM on Windows (eg, with VMWare)

* Document how to deal with certificate pinning and other things that may make
  testing certificate validation logic difficult.

* Configuration option for disabling PacketThief when managing firewall rules

* SSLTest Command-line
  * Command line option to pause between tests
  * Command line option to print a list of all tests
  * Print results
  * Command line option to specify where to write the results to

vim:ft=markdown
