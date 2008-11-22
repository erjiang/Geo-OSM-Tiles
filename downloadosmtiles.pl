#! perl

use 5.008008;
use strict;
use warnings;
use Geo::OSM::Tiles qw( :all );
use LWP::UserAgent;
use File::Path;
use File::Basename;
use Getopt::Long;

our $baseurl = "http://tile.openstreetmap.org";

our $usage = qq{Usage: 
   $0 --latitude=d[:d] --longitude=d[:d] --zoom=z[:z]
   $0 --link=url [--latitude=d[:d]] [--longitude=d[:d]] [--zoom=z[:z]]
};

our %opt = (
    latitude => undef,
    longitude => undef,
    zoom => undef,
    link => undef,
);

die "$usage\n"
    unless GetOptions(\%opt,
                      "latitude=s", "longitude=s", "zoom=s", "link=s") &&
           @ARGV == 0;

sub parserealopt;
sub parseintopt;
sub downloadtile;

if ($opt{link}) {
    die "Invalid link: $opt{link}\n"
	unless $opt{link} =~ /^http:\/\/.*\/\?lat=(-?[0-9]+\.[0-9]+)\&lon=(-?[0-9]+\.[0-9]+)\&zoom=([0-9]+)/;
    $opt{latitude} ||= $1;
    $opt{longitude} ||= $2;
    $opt{zoom} ||= $3;
}

our $lwpua = LWP::UserAgent->new;

our ($latmin, $latmax) = parserealopt("latitude");
our ($lonmin, $lonmax) = parserealopt("longitude");
our ($zoommin, $zoommax) = parseintopt("zoom");

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
    die "Invalid $optname: $opt{$optname}\n"
	unless $opt{$optname} =~ /^(-?\d+\.\d+)(?::(-?\d+\.\d+))?$/;
    my ($min, $max) = ($1, $2);
    $max = $min unless defined($max);

    return ($min, $max);
}


sub parseintopt
{
    my ($optname) = @_;
    die "Invalid $optname: $opt{$optname}\n"
	unless $opt{$optname} =~ /^(\d+)(?::(\d+))?$/;
    my ($min, $max) = ($1, $2);
    $max = $min unless defined($max);

    return ($min, $max);
}


sub downloadtile
{
    my ($lwpua, $tilex, $tiley, $zoom) = @_;
    my $path = tile2path($tilex, $tiley, $zoom);

    mkpath(dirname($path));
    my $res = $lwpua->get("$baseurl/$path", 
			  ':content_file' => $path);
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

=item *

By now, only Mapnik tiles are supported.  The base URL
L<http://tile.openstreetmap.org/> is hard coded.

=back

=head1 AUTHOR

Rolf Krahl E<lt>rolf@rotkraut.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Rolf Krahl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
