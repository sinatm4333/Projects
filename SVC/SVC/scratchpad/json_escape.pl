#!/usr/bin/perl
use strict;
use warnings;

my ($infile, $outfile) = @ARGV;
open(my $fh, "<:raw", $infile) or die $!;
local $/;
my $content = <$fh>;
close $fh;

$content =~ s/\\/\\\\/g;
$content =~ s/"/\\"/g;
$content =~ s/\r\n/\n/g;
$content =~ s/\n/\\n/g;
$content =~ s/\t/\\t/g;

open(my $out, ">:raw", $outfile) or die $!;
print $out $content;
close $out;
