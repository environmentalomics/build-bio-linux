#/usr/bin/perl
#
#makes the expected structure for a package primed for packaging
#Dan Swan (dswan@bioinformatics.org) 20041203

use warnings;
use strict;

my $menu=0;

print "What is the name of the package (bio-linux-?): ";
chomp (my $package=(<STDIN>));
my $packagename="bio-linux-".$package;
print "Package name is $packagename\n";
print "Does the package need a menu (interactive shell or GUI)?: ";
chomp (my $response=(<STDIN>));
if ($response =~ /[y|Y]/) {
	$menu=1;
        }else{
        $menu=0;
        }
print "Menu value is $menu\n"
                                
