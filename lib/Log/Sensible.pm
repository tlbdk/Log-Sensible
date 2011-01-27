package Log::Sensible; 
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

#TODO: This module uses globals to hold the log level, and this might be a problem.

=head1 NAME

Misc::Logger - A collection of function used for logging

=head1 DESCRIPTION

=head1 SYNOPSIS
  
=cut

use base "Exporter";

our @EXPORT = qw(trace debug info warning error fatal);

use POSIX qw(strftime);
use Sys::Syslog;

my $MAILLEVEL   = -1;
my $MAILSUBJECT = '';
my $MAILFROM    = '';
my $MAILTO      = '';

my $LOGLEVEL  = 3;
my $MAINNAME  = 'main';
my $TYPE      = 'STDOUT';

my %levels = (
    trace   => 5, 
    debug   => 4,
    info    => 3,
    warning => 2,
    error   => 1,
    fatal   => 0,
    off     => -1,
);

sub trace   { logger(5, 'TRACE', @_); }
sub debug   { logger(4, 'DEBUG', @_); }
sub info    { logger(3, 'INFO', @_); }
sub warning { logger(2, 'WARN', @_); }
sub error   { logger(1, 'ERROR', @_); }
sub fatal   { logger(0, 'FATAL', @_); }

# Catch signals that will kill the us and print error
my $handler = sub {
    $SIG{$_[0]} = 'IGNORE';
    fatal("Got killed by $_[0] signal");
    exit;
};
map { $SIG{$_} = $handler } qw(HUP INT PIPE TERM ABRT BUS FPE ILL QUIT 
SEGV SYS TRAP);

sub sendmail {
    my ($caller, $type, $msg) = @_;

    info("Sending mail to $MAILTO");
    open(my $cmd, "|/usr/sbin/sendmail -t") or die "Cannot open sendmail\: $!";
    print {$cmd} 
        "Reply-to: $MAILFROM\n"
        ."Subject: $MAILSUBJECT $type from $caller\n"
        ."To: $MAILTO\n"
        ."Content-type: text/plain\n\n"
        .$msg;
    close $cmd;
}

sub mail {
    my($level, $subject, $from, $to) = @_;

    croak "no arguments given" if @_ == 0;
    croak "level not defined" if !defined $level;
    
    if($level =~ /^\d$/) {
        croak "level $level not i range 0-5" if $level < 0 or $level > 5;
        $MAILLEVEL = $level;

    } elsif(exists $levels{lc($level)}) {
        $MAILLEVEL = $levels{lc($level)};

    } else {
        croak "unknown level $level";
    }

    $MAILSUBJECT = $subject;
    $MAILFROM = $from;
    $MAILTO = $to;
}

sub level {
    my($level) = @_;

    croak "no arguments given" if @_ == 0;
    croak "level not defined" if !defined $level;
    
    if($level =~ /^\d$/) {
        croak "level $level not i range 0-5" if $level < 0 or $level > 5;
        $LOGLEVEL = $level;

    } elsif(exists $levels{lc($level)}) {
        $LOGLEVEL = $levels{lc($level)};

    } else {
        croak "unknown level $level";
    }
}

sub type {
    my($type, @args) = @_;
    
    croak "no arguments given" if @_ == 0;
    croak "type not defined" if !defined $type;

    if(uc($type) eq 'STDOUT') {
        $TYPE = 'STDOUT';

    } elsif(uc($type) eq 'SYSLOG') {
        $TYPE = 'SYSLOG';
        
        # Set up signals we want to catch. Let's log warnings and fatal errors
        $SIG{__WARN__} = sub {
            warning(join(" ", @_));
        };
        $SIG{__DIE__} = sub { 
            if($^S) {
                die @_;
            } else {
                fatal(join(" ", @_));
                die @_;
            }
        };

    } else {
        croak "unknown type $type";
    }
}

sub name {
    my($name) = @_;
    
    croak "no arguments given" if @_ == 0;
    croak "name not defined" if !defined $name;
    
    $MAINNAME = $name;
}

sub logger {
    my ($level, $type, @args) = @_;
  
    if($LOGLEVEL >= $level) {
        my $time = strftime "%b %e %H:%M:%S %Y", localtime;
        
        my $caller = caller(1);
        if($caller eq 'main' or $caller eq 'Log::Sensible') {
            $caller = $MAINNAME;
        }
        
        if(@args > 1) {
            if($TYPE eq 'STDOUT') {
                print "$time $type($args[0]): $args[1]\n";
            
            } elsif($TYPE eq 'SYSLOG') {
                foreach my $msg (split "\n", $args[1]) {
                    $msg =~ s/\t/  /g;
                    syslog('INFO', "$args[0]($type): $msg");
                }
            }
            
            sendmail($args[0], $type, $args[1]) if $MAILLEVEL >= $level;

        } else {
            if($TYPE eq 'STDOUT') {
                print "$time $type($caller): $args[0]\n";
            } elsif($TYPE eq 'SYSLOG') {
                foreach my $msg (split "\n", $args[0]) {
                    $msg =~ s/\t/  /g;
                    syslog('INFO', "$caller($type): $msg");
                }
            }

            sendmail($caller, $type, $args[0]) if $MAILLEVEL >= $level;
        }
    }
}

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2005-2007 Troels Liebe Bentsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

