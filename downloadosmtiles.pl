#! perl

use 5.006001;
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

    # Note that ($lat - $offs, $lat + $offs) or
    # ($lon - $offs, $lon + $offs) may get out of the acceptable range
    # of coordinates.  This will eventually get corrected by
    # checklatrange or checklonrange later on.

    $opt{latitude} = [ $lat - $offs, $lat + $offs ]
	unless defined($opt{latitude});
    $opt{longitude} = [ $lon - $offs, $lon + $offs ]
	unless defined($opt{longitude});
    $opt{zoom} = $zoom
	unless defined($opt{zoom});
}

our $lwpua = LWP::UserAgent->new;
$lwpua->env_proxy;

our ($latmin, $latmax) = checklatrange(parserealopt("latitude"));
our ($lonmin, $lonmax) = checklonrange(parserealopt("longitude"));
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
=head1 NAME

downloadosmtiles.pl - Download map tiles from OpenStreetMap

=head1 SYNOPSIS

  downloadosmtiles.pl --lat=49.5611:49.6282 --lon=10.951:11.0574 --zoom=13:14
  downloadosmtiles.pl --link='http://www.openstreetmap.org/?lat=-23.5872&lon=-46.6508&zoom=12&layers=B000FTF'

=head1 DESCRIPTION

This script downloads all map tiles from an OpenStreetMap tile server
for some geographic region in a range of zoom levels.  The PNG images
of the tiles are stored in a directory tree that mirrors the paths
from the server.

A bounding box of geographic coordinates and a range of zoom levels
must be selected by command line options.

=head1 COMMAND LINE OPTIONS

Command line options may be abbreviated as long as they remain
unambiguous.

At least either C<--latitude>, C<--longitude>, and C<--zoom> or
C<--link> must be specified.

=head2 C<--latitude=latmin[:latmax]>

Selects the latitude of the bounding box of coordinates to download.
May be one single real value or two real values separated by a colon
in the range C<-85.0511..85.0511>.  If given only one value, just the
tile (or row of tiles) at this latitude will be downloaded.

Default: none

=head2 C<--longitude=lonmin[:lonmax]>

Selects the longitude of the bounding box of coordinates to download.
May be one single real value or two real values separated by a colon
in the range C<-180.0..180.0>.  If given only one value, just the tile
(or column of tiles) at this longitude will be downloaded.

Default: none

=head2 C<--zoom=zoommin[:zoommax]>

Selects the range of zoom levels to download the map tiles for.  May
be one single integer value or two integer values separated by a
colon.  OpenStreetMap supports zoom levels in the range C<0..18>.
(This depends on the base URL and is not enforced by this script.)

Default: none

=head2 C<--link=url>

An URL selecting C<--latitude>, C<--longitude>, and C<--zoom> in one
argument.  The idea is to select the current view of OSM's slippy map
by its permalink.

The argument to C<--link> must be an URL containing the HTTP options
C<?lat=s&lon=s&zoom=s>.  (Actually, the base URL will be ignored.)
The script chooses a box around the latitude and longitude options.
The size of the box depends on the zoom option.

If combined with C<--latitude>, C<--longitude>, or C<--zoom>, these
explicitly specified values override the implicitly specified values
from C<--link>.

Default: none

=head2 C<--baseurl=url>

The base URL of the server to download the tiles from.

Default: L<http://tile.openstreetmap.org>
(This is the base URL for the Mapnik tiles.)

=head2 C<--destdir=dir>

The directory where the tiles will be stored.  The PNG files will be
stored as C<dir/zoom/x/y.png>.

Default: The current working directory.

=head1 EXAMPLE

Select the region of interest in OSM's slippy map and follow the
permalink in the lower left of the window.  Lets this permalink
to be
L<http://www.openstreetmap.org/?lat=49.5782&lon=11.0076&zoom=12&layers=B000FTF>.
Then

  downloadosmtiles.pl --link='http://www.openstreetmap.org/?lat=49.5782&lon=11.0076&zoom=12&layers=B000FTF' --zoom=5:18

will download all tiles from zoom level 5 to 18 for this region.

=head1 BUGS

=over

=item *

Ranges in the command line options must always be increasing.  While
this is considered a feature for C<--latitude> and C<--zoom>, it means
that it is impossible for a range in the C<--longitude> argument to
cross the 180 degree line.  A command line option like
C<--longitude=179.5:-179.5> will not work as one should expect.

=item *

The bounding box selected by the C<--link> command line option does
not always correspond to the current view in the slippy map.  The
problem is that the permalink from the slippy map only contains one
position and not the bounds of the current view.  The actual view of
the slippy map depends on many factors, including the size of the
browser window.  Thus, there is not much that can be done about this
issue.

=item *

The script lacks a progress indicator.  Selecting a large bounding box
or a large range of zoom levels may result in a large number of tiles
to be downloaded.  This may easily take half an hour or longer.  Since
there is no progress indicator, the script seems to hang while it is
actually working fine.

=back

=head1 SEE ALSO

L<http://wiki.openstreetmap.org/wiki/Slippy_Map>

=head1 AUTHOR

Rolf Krahl E<lt>rolf@rotkraut.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Rolf Krahl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
