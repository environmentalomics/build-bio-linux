#!/usr/bin/perl 

use warnings;
use strict;

#tag each Version: line with -1

print "(o)Reading list of directories\n";
opendir (SOFTWARE, "./") or die "Error in opendir: $!\n";
my @package_list = grep !/^\./, readdir SOFTWARE;
closedir (SOFTWARE) or die "Error in closedir: $!\n";

foreach (@package_list) {

if ($_ =~ /bio/) {
my $provides;
my $packagename=$_;
	open (READ, "$_/DEBIAN/control") or die "no\n";
	open (WRITE, ">$_/DEBIAN/control.new") or die "no1\n";
	while (<READ>) {
		if (/Package/) {
			($provides) = $_ =~ /Package:\ (.*)/;
			print "$provides\n";
			}else{}
		if (/Provides/) {
			$_="";
			print WRITE "Provides: $provides\n";
			}else{}
		if (/Version/) {
			print "$_\n";
			chomp;
			print WRITE "$_-1\nSection: science\nPriority: optional\nDepends: bio-linux-base-directories (>= 1.0-1)\n";
		}else{print WRITE "$_";
		}
	}
close (READ);
close (WRITE);

print "We were modifying: $packagename\n";
unlink("$packagename/DEBIAN/control");
`mv $packagename/DEBIAN/control.new $packagename/DEBIAN/control`;

}else{}

}
