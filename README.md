Certificate Maker
=================

Rake tasks and Ruby code that generate a variety of SSL certificates for
testing certificate validation.

Currently, the code provides two approaches to certificate generation:

1. Rake tasks that take a file dependency approach to defining the certificates
2. A Ruby DSL that is a little cleaner

The Rake tasks are located in lib/tasks/ssl.rb, which can be difficult to
understand. It uses `openssl ca` to manage the CAs it generates, and it uses
certificate signing requests and such to generate each certificate. It also
generates "chains" of certificates for certain deployments. It depends heavily
on OpenSSL's configuration files, which can be confusing to debug. Int his
case, they config files are generated using ERB templates in order to insert an
arbitrary CNAME into them for testing. This approach can be run using:

    rake ssl

The second approach defines a class that represents each certificate and its
associated files. Behind the scenes, it performs the same work as the Rake
tasks, but it avoids using `openssl ca` (this has the drawback that it doesn't
seem possible to set arbitrary expiration information, although you can make a
certificate that expires before it was valid). Its advantage is that it is a
little easier to understand how it works. It can be run using:

    ruby runner.rb

Note that both approaches generate files in the same place. To remove the
generated files:

    rake clean

The eventual goal is a DSL or single configuration file that easily describes
how the certificates vary, and using Ruby's standard OpenSSL library calls.
