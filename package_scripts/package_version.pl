#!/usr/bin/perl
#
#creates a menu entry for the software

use warnings;
use strict;

print "(o)Reading list of directories\n";
opendir (SOFTWARE, "./") or die "Error in opendir: $!\n";
my @package_list = grep !/^\./, readdir SOFTWARE;
closedir (SOFTWARE) or die "Error in closedir: $!\n";

foreach (@package_list) {
	

opendir (DESKTOP, "$_/etc/menu/");
my @desktop_list = grep !/^\./, readdir DESKTOP;
closedir (DESKTOP);
my $desktop=$desktop_list[0];
print "Desktop $desktop\n";
my @newfile=split(/\./ , $desktop);
my $newfile=$newfile[0];
print "Newfile $newfile\n";
`mv $_/etc/menu/$desktop $_/etc/menu/$newfile`;
}
					
