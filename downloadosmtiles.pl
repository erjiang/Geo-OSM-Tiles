#! perl

use 5.008008;
use strict;
use warnings;
use Geo::OSM::Tiles qw( :all );
use LWP::UserAgent;
use File::Path;
use File::Basename;
use Cwd qw(cwd);
use Getopt::Long;

our $linkrgoffs = 350.0;

our $usage = qq{Usage: 
   $0 --latitude=d[:d] --longitude=d[:d] --zoom=z[:z] [--baseurl=url] [--destdir=dir]
   $0 --link=url [--latitude=d[:d]] [--longitude=d[:d]] [--zoom=z[:z]] [--baseurl=url] [--destdir=dir]
};

our %opt = (
    latitude => undef,
    longitude => undef,
    zoom => undef,
    link => undef,
    baseurl => "http://tile.openstreetmap.org",
    destdir => cwd,
);

die "$usage\n"
    unless GetOptions(\%opt,
                      "latitude=s", "longitude=s", "zoom=s", "link=s",
                      "baseurl=s", "destdir=s") &&
           @ARGV == 0;

sub parserealopt;
sub parseintopt;
sub downloadtile;

if ($opt{link}) {
    die "Invalid link: $opt{link}\n"
	unless $opt{link} =~ /^http:\/\/.*\/\?lat=(-?[0-9]+(?:\.[0-9]+)?)\&lon=(-?[0-9]+(?:\.[0-9]+)?)\&zoom=([0-9]+)/;
    my $lat = $1;
    my $lon = $2;
    my $zoom = $3;
    my $offs = $linkrgoffs / 2**$zoom;

    my $latmin = $lat - $offs;
    $latmin = -85.0511 if $latmin < -85.0511;
    my $latmax = $lat + $offs;
    $latmax = 85.0511 if $latmax > 85.0511;
    $opt{latitude} = [ $latmin, $latmax ]
	unless defined($opt{latitude});
    my $lonmin = $lon - $offs;
    $lonmin = -180.0 if $lonmin < -180.0;
    my $lonmax = $lon + $offs;
    $lonmax = 179.9997 if $lonmax > 179.9997;
    $opt{longitude} = [ $lonmin, $lonmax ]
	unless defined($opt{longitude});
    $opt{zoom} = $zoom
	unless defined($opt{zoom});
}

our $lwpua = LWP::UserAgent->new;
$lwpua->env_proxy;

our ($latmin, $latmax) = parserealopt("latitude");
our ($lonmin, $lonmax) = parserealopt("longitude");
our ($zoommin, $zoommax) = parseintopt("zoom");
our $baseurl = $opt{baseurl};
our $destdir = $opt{destdir};

for my $zoom ($zoommin..$zoommax) {
    my $txmin = lon2tilex($lonmin, $zoom);
    my $txmax = lon2tilex($lonmax, $zoom);
    # Note that y=0 is near lat=+85.0511 and y=max is near
    # lat=-85.0511, so lat2tiley is monotonically decreasing.
    my $tymin = lat2tiley($latmax, $zoom);
    my $tymax = lat2tiley($latmin, $zoom);
    for my $tx ($txmin..$txmax) {
	for my $ty ($tymin..$tymax) {
	    downloadtile($lwpua, $tx, $ty, $zoom);
	}
    }
}


sub parserealopt
{
    my ($optname) = @_;

    if (ref($opt{$optname})) {
	return @{$opt{$optname}};
    }
    else {
	die "Invalid $optname: $opt{$optname}\n"
	    unless $opt{$optname} =~ /^(-?\d+\.\d+)(?::(-?\d+\.\d+))?$/;
	my ($min, $max) = ($1, $2);
	$max = $min unless defined($max);

	return ($min, $max);
    }
}


sub parseintopt
{
    my ($optname) = @_;

    if (ref($opt{$optname})) {
	return @{$opt{$optname}};
    }
    else {
	die "Invalid $optname: $opt{$optname}\n"
	    unless $opt{$optname} =~ /^(\d+)(?::(\d+))?$/;
	my ($min, $max) = ($1, $2);
	$max = $min unless defined($max);

	return ($min, $max);
    }
}


sub downloadtile
{
    my ($lwpua, $tilex, $tiley, $zoom) = @_;
    my $path = tile2path($tilex, $tiley, $zoom);
    my $url = "$baseurl/$path";
    my $fname = "$destdir/$path";

    mkpath(dirname($fname));
    my $res = $lwpua->get($url, ':content_file' => $fname);
    die $res->status_line
	unless $res->is_success;
}


__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

downloadosmtiles.pl - Download map tiles from OpenStreetMap

=head1 SYNOPSIS

  downloadosmtiles.pl --lat=49.5611:49.6282 --lon=10.951:11.0574 --zoom=13:14
  downloadosmtiles.pl --link='http://www.openstreetmap.org/?lat=-23.5872&lon=-46.6508&zoom=12&layers=B000FTF'

=head1 DESCRIPTION

Blah blah blah.

=head1 BUGS

=over

=item *

Ranges in the command line options must always be increasing.  While
this is considered a feature for C<--latitude> and C<--zoom>, it means
that it is impossible for a range in the C<--longitude> argument to
cross the 180 degree line.  A command line option like
C<--longitude=179.5:-179.5> will not work as one should expect.

=back

=head1 AUTHOR

Rolf Krahl E<lt>rolf@rotkraut.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Rolf Krahl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
