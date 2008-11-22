#! perl

use 5.008008;
use strict;
use warnings;
use Geo::OSM::Tiles qw( :all );
use LWP::UserAgent;
use File::Path;
use File::Basename;
use Getopt::Long;

our $usage = qq{Usage: 
   $0 --latitude=d --longitude=d --zoom=z
   $0 --link=url [--latitude=d] [--longitude=d] [--zoom=z]
};

our %opt = (
    latitude => undef,
    longitude => undef,
    zoom => undef,
    link => undef,
);

die "$usage\n"
    unless GetOptions(\%opt,
                      "latitude=s", "longitude=s", "zoom=i", "link=s") &&
           @ARGV == 0;

sub downloadtile;

if ($opt{link}) {
    die "Invalid link: $opt{link}\n"
	unless $opt{link} =~ /http:\/\/.*\/\?lat=([0-9]+\.[0-9]+)\&lon=([0-9]+\.[0-9]+)\&zoom=([0-9]+)/;
    $opt{latitude} ||= $1;
    $opt{longitude} ||= $2;
    $opt{zoom} ||= $3;
}

# FIXME: Parsing of options and error check.

our $lwpua = LWP::UserAgent->new;

our $lat = $opt{latitude};
our $lon = $opt{longitude};
our $zoom = $opt{zoom};
our $tilex = lon2tilex($lon, $zoom);
our $tiley = lat2tiley($lat, $zoom);

downloadtile($tilex, $tiley, $zoom);



sub downloadtile
{
    my ($tilex, $tiley, $zoom) = @_;
    my $path = tile2path($tilex, $tiley, $zoom);

    mkpath(dirname($path));
    my $res = $lwpua->get("http://tile.openstreetmap.org/$path", 
			  ':content_file' => $path);
    die $res->status_line
	unless $res->is_success;
}
