#!/usr/bin/perl -w

use strict;

my $gaimlogs = "/home/ckdake/.gaim/logs/aim/ckdake";

foreach (<$gaimlogs/*>) {
    foreach (<$_/*>) {
        if (/\.\./) {
            my $was = $_;
            s/\.\./\.000000\./;
            system("mv $was $_\n");
        }
    }
}