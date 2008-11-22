package Geo::OSM::Tiles;

use 5.008008;
use strict;
use warnings;
use Math::Trig;

require Exporter;

our $VERSION = '0.01';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	lon2tilex lat2tiley tile2path
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();


sub lon2tilex
{
    my ($lon, $zoom) = @_;

    return int( ($lon+180)/360 * 2**$zoom );
}

sub lat2tiley
{
    my ($lat, $zoom) = @_;
    my $lata = $lat*pi/180;

    return int( (1 - log(tan($lata) + sec($lata))/pi)/2 * 2**$zoom );
}

sub tile2path
{
    my ($tilex, $tiley, $zoom) = @_;

    return "$zoom/$tilex/$tiley.png";
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::OSM::Tiles - Calculate tile numbers from OpenStreetMap

=head1 SYNOPSIS

  use Geo::OSM::Tiles qw( :all );

  $zoom = 13;
  $lat = 49.60055;
  $lon = 11.01296;
  $tilex = lon2tilex($lon, $zoom);
  $tiley = lat2tiley($lat, $zoom);
  $path = tile2path($tilex, $tiley, $zoom);
  $tileurl = "http://tile.openstreetmap.org/$path";

=head1 DESCRIPTION

Stub documentation for Geo::OSM::Tiles, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames>

=head1 AUTHOR

Rolf Krahl E<lt>rolf@rotkraut.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Rolf Krahl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
