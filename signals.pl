#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;

use Sys::SigAction;

use POSIX;
use Data::Dumper;
$Data::Dumper::Useqq = 1;

my $perl_510 = 0;
my $perl_588 = 0;

my $inf;
my @result;

print Dumper(\%SIG);

if($perl_510) {
    POSIX::sigaction(
        SIGINT,
        POSIX::SigAction->new(
            sub {
                $inf = Dumper \@_;
                @result = unpack "LLLLSL", $_[2];     # <--
            },
            0,
            POSIX::SA_SIGINFO
        ),
    );

} elsif($perl_588) { # not working 
    Sys::SigAction::set_sig_handler(
        SIGINT,
        sub {
            $inf = Dumper \@_;
            @result = unpack "LLLLSL", $_[2];     # <--
        },
        { flags => POSIX::SA_SIGINFO }
    );

} else {
    my $handler = sub { $inf = Dumper \@_; }; 
    map { $SIG{$_} = $handler } 
        qw(HUP INT PIPE TERM ABRT BUS FPE ILL QUIT SEGV SYS TRAP);
}

print "Own PID:    $$\n";

#kill 'INT', $$;
while(1) {
    sleep 1000;
    print $inf;
    print "Sender PID: ".join(", ",@result)."\n";
    print "Own PID:    $$\n";
}
    #sleep 1000;
