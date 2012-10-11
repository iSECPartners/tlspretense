#!/bin/sh

rbversion=$(ruby --version)

if [ "${RUBY}x" == "x" ] ; then
    if ruby --version | grep -q '1\.9' ; then
        RUBY=ruby
    elif ruby1.9 --version | grep -q '1\.9' ; then
        RUBY=ruby1.9
    fi
fi

sudo bundle exec ${RUBY} bin/ssl_test_runner.rb $@
