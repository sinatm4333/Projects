#!/usr/bin/perl
# Usage: perl extract_tybot_attachment.pl <tybot_file> <attachment_name>
# Extracts and base64-decodes one attachment's file_content by matching its "name" field.
use strict;
use warnings;
use MIME::Base64;

my ($file, $name) = @ARGV;
open(my $fh, "<:raw", $file) or die "Cannot open $file: $!";
local $/;
my $content = <$fh>;
close $fh;

# Find each attachment object roughly: {"file_content":"...","id":...,"mime":"...","name":"...","size":...}
while ($content =~ /"file_content":"([^"]*)","id":\d+,"mime":"[^"]*","name":"([^"]*)","size":\d+/g) {
    my ($b64, $attname) = ($1, $2);
    if ($attname eq $name) {
        print decode_base64($b64);
        exit 0;
    }
}
print STDERR "Attachment '$name' not found in $file\n";
exit 1;
