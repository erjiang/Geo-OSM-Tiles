use Test::More tests => 40;
BEGIN { use_ok('Geo::OSM::Tiles', qw(:all)) };

# Simple tests of well known values.

# 2..4
my $zoom = 13;
my $lat = 49.60055;
my $lon = 11.01296;
my $tilex = lon2tilex($lon, $zoom);
is($tilex, 4346, "tile x at lon = $lon, zoom = $zoom");
my $tiley = lat2tiley($lat, $zoom);
is($tiley, 2792, "tile y at lat = $lat, zoom = $zoom");
my $path = tile2path($tilex, $tiley, $zoom);
is($path, '13/4346/2792.png', "path");


# Check the bound checking in checklonrange and checklatrange.

# 5..40
# A range of coordinates that is out of bounds for sure.
my @hugerange = (-1000.0, 1000.0);
for $zoom (0, 1, 2, 5, 10, 15, 18, 20, 30) {
    # 4 tests per zoom level
    my $max = 2**$zoom-1;

    my ($lonmin, $lonmax) = checklonrange(@hugerange);
    my ($xmin, $xmax) = map { lon2tilex($_, $zoom) } ($lonmin, $lonmax);
    is($xmin, 0, "\$xmin at zoom = $zoom");
    is($xmax, $max, "\$xmax at zoom = $zoom");

    # Note that lat2tiley is decreasing,
    # so $ymin = lat2tiley($latmax, $zoom).
    my ($latmin, $latmax) = checklatrange(@hugerange);
    my ($ymax, $ymin) = map { lat2tiley($_, $zoom) } ($latmin, $latmax);
    is($ymin, 0, "\$ymin at zoom = $zoom");
    is($ymax, $max, "\$ymax at zoom = $zoom");
}


# Local Variables:
# mode: perl
# End:
