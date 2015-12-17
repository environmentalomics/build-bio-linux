#!/usr/bin/perl
#/home/tbooth/scripts/make_package_list.perl - created Tue Aug 13 14:13:48 BST 2013

use strict;
use warnings;
use Data::Dumper;

# Currently, the /home/manager/package_scripts/update_repository script on Envgen
# makes a list of packages for the website.  This is very incomplete and
# is missing versions.  How to fix it?

# 1) Look at ~/sandbox/bl7_things/bl_master_package_list.txt
#    (trim anything after a space)
#    But this has loads of system crud in, and will miss new stuff added to
#    launchpad.  Maybe just search for "Science"?
# 2) Grab list from Launchpad.  This gets a few bits of crud but we can
#    blacklist.
# 3) Grab from Envgen as before.  If anything has 'bl' in the version then
#    add all dependencies that are in section "Science", else chop name.
#
# OK, that's complicated.  Let's give it a whirl.

my @master_package_list;

my @lp_package_list;

my @envgen_package_list;

my @dep_package_list;

my @blacklist = qw( 
   arb-common estscan libarb prot4est  *-all *-data *-data-* *-examples *-test
);

my %pkgs; #For the final result.

# 1

@master_package_list = wgrab("http://nebc.nerc.ac.uk/downloads/bl7_only/bl_master_package_list.txt");
map { s/ .*// } @master_package_list;

@lp_package_list = wgrab("http://ppa.launchpad.net/nebc/bio-linux/ubuntu/dists/precise/main/binary-amd64/Packages.bz2");

@envgen_package_list = wgrab("http://nebc.nerc.ac.uk/bio-linux/dists/unstable/bio-linux/binary-amd64/Packages.gz");

MPL: for(@master_package_list)
{
    chomp;

    #Skip bio-linux- packages at this stage.
    /^bio-linux-/ && next;

    my @showlines = `apt-cache show $_`;
    my %showinfo;

    for(@showlines)
    {
	chomp;
	#Only get the first bit.
	$_ eq '' and last;
	
	/^([A-Za-z-]+): ?(.*)/ or next;
	$showinfo{$1} = $2;
    }

    for($showinfo{Section})
    {
	$_ or die "No info found - maybe this machine doesn't have the right sources configured?\n",
		  "HINT- this script won't work on Envgen, it needs to be run on a BL machine.\n",
	  	  Dumper(\%showinfo);

	/(?:^|\/)science/ or /(?:^|\/)gnu-r/ or next MPL;
    }

    my $item = $pkgs{$_} = [];
    $item->[0] = $showinfo{Version} || "unknown";
    $item->[1] = $showinfo{Description} || $showinfo{"Description-en"} || "No description";
}

# 2
push @lp_package_list, '';
my %showinfo;
LPL: for(@lp_package_list)
{
    chomp;
    
    if($_ eq '' and %showinfo)
    {
	for($showinfo{Section})
	{
	    /(?:^|\/)science/ or /(?:^|\/)gnu-r/ or next LPL;
	}

	$showinfo{Package} or die Dumper(\%showinfo);
	my $item = $pkgs{$showinfo{Package}} = [];
	$item->[0] = $showinfo{Version} || "unknown";
	$item->[1] = $showinfo{Description} || $showinfo{"Description-en"} || "No description";	

	%showinfo = ();
	next;
    }

    /^([A-Za-z-]+): ?(.*)/ or next;
    $showinfo{$1} = $2;
}

# 3
my $lastfield = '';
push @envgen_package_list, '';
%showinfo = ();
EPL: for(@envgen_package_list)
{
    chomp;
    
    if($_ eq '' and %showinfo)
    {
	for($showinfo{Package})
	{
	    $_ or die Dumper(\%showinfo);

	    #Skip non bio-linux- stuff for now
	    /^bio-linux-(.+)/ or next EPL;
	    $showinfo{Pkg} = $1;
	}

	#If this is a wrapper, add all deps in Science.  Else add the package.
	for($showinfo{Version})
	{
	    if(/bl/ or $pkgs{$showinfo{Pkg}})
	    {
		for(split(/[,|]/, $showinfo{Depends} || ''))
		{
		    s/\(.*//; s/\s+$//; s/^\s+//;
		    push @dep_package_list, $_ if $_ and ( ! /^bio-linux-/) ;
		}
	    }
	    else
	    {
		my $item = $pkgs{$showinfo{Pkg}} = [];
		$item->[0] = $showinfo{Version} || "unknown";
		$item->[1] = $showinfo{Description} || $showinfo{"Description-en"} || "No description";	
	    }
	}

	%showinfo = ();
	$lastfield = '';
	next EPL;
    }

    if(/^([A-Za-z-]+): ?(.*)/)
    {
	$lastfield = $1;
	$showinfo{$1} = $2;
    }
    elsif($lastfield eq 'Depends')
    {
	$showinfo{Depends} .= $_;
    }
}

DPL: for(@dep_package_list)
{
    chomp;

    #Skip repeats
    $pkgs{$_} and next;

    my @showlines = `apt-cache show $_`;
    my %showinfo;

    #Some deps are not available.
    next unless @showlines;
    for(@showlines)
    {
	chomp;
	#Only get the first bit.
	$_ eq '' and last;
	
	/^([A-Za-z-]+): ?(.*)/ or next;
	$showinfo{$1} = $2;
    }

    if(!$showinfo{Section}){ die Dumper $_, \@showlines, \%showinfo }

    for($showinfo{Section})
    {
	/(?:^|\/)science/ or /(?:^|\/)gnu-r/ or next DPL;
    }

    my $item = $pkgs{$_} = [];
    $item->[0] = $showinfo{Version} || "unknown";
    $item->[1] = $showinfo{Description} || $showinfo{"Description-en"} || "No description";
}

# OK, that should have hoovered up everything.  Now just dump it out.
for(sort keys(%pkgs))
{
    next if contains_glob( \@blacklist, $_ );

    #Prune -rev off version
    $pkgs{$_}->[0] =~ s/(.*)-.*/$1/;

    print "$_\t$pkgs{$_}->[0]\t$pkgs{$_}->[1]\n";
}

sub contains_glob
{
    my ( $list, $item ) = @_;

    for( @$list )
    {
	my $match = $_;
        $match =~ s/\./\\./g;
        $match =~ s/\*/.*/g;
        $match =~ s/\?/./g;

	return 1 if $item =~ /^$match$/;
    }
    return 0;
}


sub contains
{
    use integer;
    #Check membership in a sorted list?  Pointless to re-implement but I'm feeling this way out.
    #Actually, I never use it anyway.  Oh well.
    my ( $list, $item ) = @_;

    my $top = @$list;
    my $bot = 0;

    while( $top > $bot )
    {
	my $idx = $bot + (($top - $bot) / 2);
	my $cmp =  $list->[$idx] cmp $item;
	if( !$cmp )        { return \$list->[$idx] }
	elsif( $cmp == 1 ) { $bot = $idx + 1 }
	else               { $top = $idx }
    }

    return undef;
}

sub wgrab
{
    require HTTP::Request;
    require LWP::UserAgent;

    my $r = HTTP::Request->new(GET => $_[0]);
    my $ua = LWP::UserAgent->new( env_proxy => 1 );

    my $res = $ua->request($r);

    $res->is_success or die $res->status_line;

    #If encoding is GZip or BZip2 then unpack it.
    my $dc;
    for($res->headers->{"content-type"})
    {
	/\/x-gzip$/ and $dc =  unz($res->content), last;
	/\/x-bzip2$/ and $dc = unbz2($res->content), last;
	$dc = $res->decoded_content;
    }
   
    split("\n", $dc);
}

#Naive decompression routines.
sub unz
{
    require IO::Uncompress::Gunzip;

    my $buf;
    IO::Uncompress::Gunzip::gunzip(\$_[0] => \$buf, Transparent => 0);
    $buf;
}

sub unbz2
{
    require IO::Uncompress::Bunzip2;

    my $buf;
    IO::Uncompress::Bunzip2::bunzip2(\$_[0] => \$buf, Transparent => 0);
    $buf;
}
