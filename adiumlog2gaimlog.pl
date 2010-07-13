#!/usr/bin/perl -w

use strict;

my $adiumlogs = "/home/ckdake/incoming/log/AIM.ckdake";
my $gaimlogs = "/home/ckdake/.gaim/logs/aim/ckdake";

foreach (<$adiumlogs/*>) {
    $_ =~ s/$adiumlogs\///;
    my $username = $_;
    if (!(-e "$gaimlogs/$username")) {
        mkdir "$gaimlogs/$username";
    }
    foreach (<$adiumlogs/$_/*>) {
        my $thingy = $_;
        my ($hour, $minute, $second);
        my ($year, $month, $day) = /\((\d{4})\|(\d{2})\|(\d{2})\)/;
        
        if (-e $_) {
            open (FILE, $_);
            while(<FILE>) {
                if ($_ =~ /\((\d\d):(\d\d):(\d\d)\)*/) {
                    ($hour, $minute, $second) = /\((\d\d):(\d\d):(\d\d)\)*/;
                    last;
                }
            }
            close (FILE);
        }
        if ($hour) { 
		if (!(-e "$gaimlogs/$username/$year-$month-$day.$hour$minute$second.txt")) {
		        system("cp \"$thingy\" \"$gaimlogs/$username/$year-$month-$day.$hour$minute$second.txt\"");
		} else {
			print ("file already exists!!\n");
		}
	}
    }
}
