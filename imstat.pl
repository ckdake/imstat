#!/usr/bin/perl -w

# this code is provided as is with absolutley no warranty of any kind. plese
# let me know if you use it or find it useful: ckdake@ckdake.com

##todo:
# regex out chat37565882781839239957.chat folders

## takes in the following command line paramaters:
# -a gaim   (gaim or adium2 defaults to gaim)
# -s ckdake (screenname defaults to whoami)
# -u ckdake (username defaults to whoami)
# -p aim    (aim yahoo icq irc etc defaults to aim)
# -n 25     (number of people to sho won the graph defaults to 25)
# -t 1      (letters to trunicate the last name to defaults to 1
# -c lines  (lines chars bytes words defaults to line)
# -w "/home/ckdake/code/imstat/aliases.txt" (file:  alias(real name)\n)
# -b 20050101  (start date defaults to first)
# -e 20050601  (end date defaults to now)
# -f png  (png or txt defaults to png)
# -o ck.png (output file, defaults to screenname.outformat)

## process all of the command line arguments.
use Getopt::Std;
my %opts;
my ($improgram, $screenname, $username, $protocol, $limit, $trunicate,
	$tocount, $aliasfile, $starton, $endon, $outformat, $outfile);
getopt('asupntcwbefo', \%opts);
if (defined $opts{'a'}) {
	$improgram = $opts{'a'};
} else {
	$improgram = "gaim";
}
print("Instant messenger program ....... " . $improgram . "\n");
if (defined $opts{'s'}) {
	$screenname = $opts{'s'};
} else {
	$screenname = `whoami`;
	chop($screenname);
}
print("IM Screenname ................... " . $screenname . "\n");
if (defined $opts{'u'}) {
	$username = $opts{'u'};
} else {
	$username = `whoami`;
	chop($username);
}
print("System username ................. " . $username . "\n");
if (defined $opts{'p'}) {
	$protocol = $opts{'p'};
} else {
	$protocol = "aim";
} 
print("IM protocol ..................... " . $protocol . "\n");
if (defined $opts{'n'}) {
	$limit = $opts{'n'};
} else {
	$limit = 50;
}
print("Top rankings to show ............ " . $limit . "\n");
if (defined $opts{'t'}) {
	$trunicate = $opts{'t'};
} else {
	$trunicate = 1;
}
print("How far to trunicate last names . " . $trunicate . "\n");
if (defined $opts{'c'}) {
	$tocount = $opts{'c'};
} else {
	$tocount = "lines";
}
print("What to count ................... " . $tocount . "\n");
if (defined $opts{'w'}) {
	$aliasfile = $opts{'w'};
} else {
	$aliasfile = "aliases.txt";
}
print("Alias file to read .............. " . $aliasfile . "\n");
if (defined $opts{'b'}) {
	$starton = $opts{'b'};
} else {
	$starton = "00000000";
}
print("Earliest record to include ...... " . $starton . "\n");
if (defined $opts{'e'}) {
	$endon = $opts{'e'};
} else {
	$endon = "99999999";
}
print("Latest record to include ........ " . $endon . "\n");
if (defined $opts{'f'}) {
	$outformat = $opts{'f'};
} else {
	$outformat = "png";
}
print("Output format ................... " . $outformat . "\n");
if (defined $opts{'o'}) {
	$outfile = $opts{'o'};
} else {
	$outfile = $screenname.".".$outformat;
}
print("Output file ..................... " . $outfile . "\n");

if ($outformat eq "png") {
    use GD::Graph::bars;
}

use strict;

my (@col, @val);
my %dict;
my $totallines = 0;
my $totalpeople = 0;
my ($folder, $bfile, $folder2);
my $firstdate = "99999999";

if ($improgram eq "gaim") {
    $folder = "/home/$username/.gaim/logs/$protocol/$screenname";
    my $protocol2 = "yahoo";
    $folder2 = "/home/$username/.gaim/logs/$protocol2/$screenname";
    $bfile = "/home/$username/.gaim/blist.xml";
} elsif ($improgram eq "adium2") {
    $folder = "/Users/$username/Library/Application\ Support/Adium\ 2.0/Users/Default/Logs/$protocol.$screenname/";
    $bfile = "/Users/$username/Libarary/Application\ Support/Adium\ 2.0/Users/Default/libgaim/blist.xml";
} else {
    die ("$improgram is not supported");
}

my @folders = `ls -d $folder/* $folder2/*`;
print("Counting ...");
foreach my $f (@folders) {
    print(".");
    chomp $f;    
    $f = "$f/* ";
    my @names = `ls $f`;
    if ($improgram eq "gaim") {
	$names[0] =~ /(\d{4})-(\d{2})-(\d{2})/;
	if ($1.$2.$3 < $firstdate) {
    	    $firstdate = $1.$2.$3;
	}
    } elsif ($improgram eq "adium") { 
    	$names[0] =~ /\((\d{4})\|(\d{2})\|(\d{2})\)/;
	if ($1.$2.$3 < $firstdate) {
    	    $firstdate = $1.$2.$3;
	}
    } 
    my $param = "";
    if ($tocount eq "bytes") {
	$param = "-c";
    } elsif ($tocount eq "chars") {
    	$param = "-m";
    } elsif ($tocount eq "lines") {
    	$param = "-l";
    } elsif ($tocount eq "words") {
        $param = "-w";
    }
    my $lines;
    #only count lines more recent or on the start date
    $lines = 0;
    my @files = `ls $f`;
    foreach my $file (@files) {
        $file =~ /(\d{4})-(\d{2})-(\d{2})/;
        if (($1.$2.$3 >= $starton) && ($1.$2.$3 <= $endon)) {
        	$_ =  `wc $param $file`;
		$_ = /(\d+) /;
		$lines += $1;
        }
    }
    if (!$lines) {
        $lines = 0;
    }
    $totallines += $lines;
    push(@val, $lines);
    $folder =~ s/\*//;
    $folder2 =~ s/\*//;
    $f =~ s/($folder|$folder2)\///;
    $f =~ s/\/\*//;
    $f =~ tr / //d;
    push(@col, $f);
}
print(". done\n");

# read in a buddy list xml file and pull out aliases from
# it and throw them into our dictionary
print("Aliasing .........");
open(BLIST,$bfile);
while (<BLIST>) {
    if (/<buddy account='$screenname'/) {
        $_ = <BLIST>;
        if (/<name>([\w|\s]+)<\/name>/) {
            my $name = $1;
            $name = lc($name);
            $name =~ tr/ //d;
            $_ = <BLIST>;
            if ($_ =~ /<alias>([\w|\s|-]+)<\/alias>/) {
                $dict{"$name"} = $1;
            }
        }
    }
}   
close(BLIST);

print("...");
# if the user gave us an alias file, look up names from it
# and put them into our dictionary giving priority to them
# over the names from their buddy list file
if (-e $aliasfile) {
    open (ALI,$aliasfile);
    while (<ALI>) {
        if (/([a-zA-Z0-9]+)\(([a-zA-Z]+\s{0,1}[a-zA-Z]+)\)/) {
            $dict{"$1"} = $2;
        }
    }
    close(ALI);
}

print("...");
# this shortens the names so if someone doesnt want to share
# all their buddies last names they dont have to
if ($trunicate) {
    while ((my $key, my $value) = each(%dict)) {
        $_ = $value;
        /([a-zA-Z]+\s{0,1}[a-zA-Z]{0,$trunicate})/;
        $dict{"$key"} = $1;
    }
}

print ("...");
# pull the aliases out of the dictionary and replace the screen 
# names with them in the list as appropriate
for(my $i = 0; $i < scalar(@col); $i++) {
    if ($dict{"$col[$i]"}) {
        $col[$i] = $dict{"$col[$i]"};
    }
}

print("...");
# combine people with the same name in the final list
# this is where we come up with percentages and the total
# number of people
for(my $i = 0; $i < scalar(@col); $i++) {
    for(my $j = $i + 1; $j < scalar(@col); $j++) {
        if ($col[$i] eq $col[$j]) {
            $val[$i] = $val[$i] + $val[$j];
            $val[$j] = 0;
            $col[$j] = "merged up";
        }
    }
    my $percent = ($val[$i] / $totallines);
    if ($percent =~ /(0\.[0-9]{4}).*/) {
        $percent = $1 * 100;
        $col[$i] = $col[$i] . " (#@ $percent%)";
    } else {
        $col[$i] = $col[$i] . " (#@ 0.0%)";
    }
    $totalpeople++;
}

print("... done\n");
print("Sorting ...................");

# sort the list based on log file size
for(my $i = 0; $i < @val; $i++) {
    for(my $j = 1; $j < @val - $i; $j++) {
        if ($val[$j-1] < $val[$j]) {
            my $temp = $val[$j-1];
            my $temp2 = $col[$j-1];
            $val[$j-1] = $val[$j];
            $col[$j-1] = $col[$j];
            $val[$j] = $temp;
            $col[$j] = $temp2;
        }
    }
}

print("...");
for (my $i = 0; $i < @col; $i++) {
    $_ = $col[$i];
    my $j = $i + 1;
    s/#@/#$j @/;
    $col[$i] = $_;
}

print("... done\n");
# if we dont have enough to meet the limit, lower
# the limit to how many names we actually have
if ($limit > scalar(@col)) {
    $limit = scalar(@col) - 1;
}

# set the first date to what we determined automatically
# or what the user specified to start with 
if ($starton == "00000000") {
	$firstdate =~ /(\d\d\d\d)(\d\d)(\d\d)/;
} else {
	$firstdate = $starton;
}
my $title = "$totallines $tocount in $improgram for $screenname since $firstdate";
my $xlabel = "top $limit of $totalpeople people";
my $ylabel = "$tocount";

# only use the data for the number of people we want to graph
my @data = ( [@col[0..$limit-1]], [@val[0..$limit-1]] );

#open up the izout file
open(FILEOUT, "> ".$outfile);

print("writing out file .............");
# draw the sweet graph
if ($outformat eq "png") {
    my $graph = new GD::Graph::bars(650,$limit * 13 + 10);
    if($title ne ''){
        $graph->set(title => "$title");
    }
    if($ylabel ne ''){
        $graph->set(y_label => "$ylabel");
    }

    if($xlabel ne ''){
        $graph->set(x_label => "$xlabel");
    }

    $graph->set(cycle_clrs => 1,
                bar_spacing => '10', 
                legend_placement => 'RB',
                #x_labels_vertical => 1,
                show_values => 1,
                #values_vertical => 1,
                bar_spacing => 0,
                rotate_chart => 1);

    $graph->set_values_font('ARIAL.TTF', 24);
    $graph->set_legend_font('ARIAL.TTF', 24);
    $graph->set_x_label_font('ARIAL.TTF', 24);
    $graph->set_y_label_font('ARIAL.TTF', 24);

    my $image = $graph->plot(\@data)->png;
    binmode FILEOUT;
    print FILEOUT $image;
} elsif ($outformat eq "txt") {
    @col = @col[0..$limit-1];
    @val = @val[0..$limit-1];
    
    my $maxpercent = ($val[0] / $totallines);

    print FILEOUT $title."\n";

    for (my $i = 0; $i < @col; $i++) {
        my $dots = (($val[$i] / $totallines) / $maxpercent) * 50;
        print FILEOUT "|";
        my $j = 0;
        for (; $j < $dots; $j++) {
            print FILEOUT "-";
        }
        for (; $j <= 50; $j++) {
            print FILEOUT " ";
        }
        print FILEOUT $col[$i];
        print FILEOUT "\n";
    }
}
print ("... done\n");
close FILEOUT;

