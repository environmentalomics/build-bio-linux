#!/usr/bin/perl
use strict;
use warnings;

use Term::ANSIColor;
use Term::ReadKey;
use Data::Dumper;

# NCat = Name and Cat
#
# Dump out files, showing the name of the file each time.
# TODO - make it support printing the first N lines of each file,
# ie. make it also do nhead.

my $columns;
if(-t STDOUT)
{
    ($columns) = GetTerminalSize();
}
else
{ 
    $ENV{ANSI_COLORS_DISABLED} = 1;
}
$columns ||= 80;

sub _b { colored( @_, 'blue'  ) };
sub _r { colored( @_, 'red'   ) };
sub _g { colored( @_, 'green' ) };

my $br = ("-" x $columns) . "\n";
print _b($br);


@ARGV = ('-') unless @ARGV;
for(@ARGV)
{
    my $fname = $_;
    if($fname eq '-')
    {
	$fname = "STDIN";
    }
    else
    {
	defined $_ and $fname .= " (->$_)" for readlink($_);
    }

    print _b("> "), _g($fname), _b(" >>>"), "\n";
    if(open(my $fh, $_))
    {
	print _b("| "), $_ for <$fh>;
	print _b($br);
	close $fh;
    }
    else
    {
	print _r("!!! UNREADABLE !!!"), "\n";
    }
}

