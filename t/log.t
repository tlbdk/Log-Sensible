use strict;
use warnings;

use Test::More tests => 1;

use Log::Sensible;
use Data::Dumper;

Log::Sensible::level('debug');
Log::Sensible::name('test');
Log::Sensible::type('syslog');

my $hash = {
    test => {
        test => {
            test => {
                test => 2,
            }
        }
    }
};

error "tftpd","Hello";
fatal "Hello";
debug "Hello";
trace "Hello";
fatal "Hello1\nHello2\nHello3";
die(Dumper($hash));

#trace "Hello";
