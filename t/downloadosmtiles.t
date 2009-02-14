use Test::More;

# Check whether we can reach the tile server first.  Otherwise it
# makes no sense to try testing the script.
use LWP::UserAgent;
eval {
    my $testurl = 'http://tile.openstreetmap.org/0/0/0.png';
    my $lwpua = LWP::UserAgent->new;
    $lwpua->env_proxy;
    my $res = $lwpua->get($testurl);
    die $res->status_line
	unless $res->is_success;
};
if ($@) {
    plan skip_all => "could not reach tile server: $@";
}
else {
    plan tests => 3 * 3 + 10;
}

use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;
use File::Find;

# you may switch off $cleanup for debugging this test script.
our $cleanup = 1;

# Hack 1:
# Problem in ExtUtils::Command::MM: the test_harness subroutine in
# ExtUtils::Command::MM fails to put the @test_libs arguments into
# $ENV{PERLLIB} in order to communicate this information to child
# processes.  Ugly, quick and dirty work around: Assume @test_libs to
# be ('blib/lib', 'blib/arch').
$ENV{PERLLIB} = abs_path('blib/lib') . ":" . abs_path('blib/arch') .
    ( $ENV{PERLLIB} ? ":$ENV{PERLLIB}" : "" );

# Hack 2:
# Is there any official way to know where the scripts will be placed
# during the test phase?
our $downloadosmtiles = abs_path('blib/script/downloadosmtiles.pl');

sub countpng;
sub cleantmp;

our $testdir = tempdir( CLEANUP => $cleanup );
our $pngcount;
our $dubiouscount;


# check whether the script is properly placed where we expect it do be
# and wheter it is executable.
# 2 tests
ok(-e $downloadosmtiles, "downloadosmtiles.pl is present");
ok(-x $downloadosmtiles, "downloadosmtiles.pl is executable");

# download single tiles for a bunch of positions
# 3 * 3 tests
{
    my @positions = (
	{
	    LAT => "0",
	    LON => "0",
	    ZOOM => "0",
	},
	{
	    LAT => "5.0",
	    LON => "-10.0",
	    ZOOM => "2",
	},
	{
	    LAT => "-41.272",
	    LON => "174.863",
	    ZOOM => "9",
	},
    );

    for (@positions) {
	my $lat = $_->{LAT};
	my $lon = $_->{LON};
	my $zoom = $_->{ZOOM};
	my $res = system($downloadosmtiles, 
			 "--latitude=$lat", "--longitude=$lon", "--zoom=$zoom",
			 "--quiet", "--destdir=$testdir");
	is($res, 0, "return value from downloadosmtiles.pl");

	$pngcount = 0;
	find(\&countpng, File::Spec->catdir($testdir, $zoom));
	is($pngcount, 1, "number of dowloaded tiles");

	$dubiouscount = 0;
	find({ wanted => \&cleantmp, bydepth => 1, no_chdir => 1 }, $testdir)
	    if $cleanup;
	ok(!$dubiouscount, "dubious files found");
    }
}


# test --link option
# 8 tests
{
    my $link = 'http://openstreetmap.org/?lat=14.692&lon=-17.448&zoom=11&layers=B000FTF';

    my $res = system($downloadosmtiles, 
		     "--link=$link", "--zoom=11:13",
		     "--quiet", "--destdir=$testdir");
    is($res, 0, "return value from downloadosmtiles.pl");

    $pngcount = 0;
    find(\&countpng, File::Spec->catdir($testdir, "11"));
    cmp_ok($pngcount, '>=', 9, "number of dowloaded tiles");
    cmp_ok($pngcount, '<=', 16, "number of dowloaded tiles");

    my $oldcount = $pngcount;
    $pngcount = 0;
    find(\&countpng, File::Spec->catdir($testdir, "12"));
    cmp_ok($pngcount, '>=', $oldcount, "number of dowloaded tiles");
    cmp_ok($pngcount, '<=', 4*$oldcount, "number of dowloaded tiles");

    $oldcount = $pngcount;
    $pngcount = 0;
    find(\&countpng, File::Spec->catdir($testdir, "13"));
    cmp_ok($pngcount, '>=', $oldcount, "number of dowloaded tiles");
    cmp_ok($pngcount, '<=', 4*$oldcount, "number of dowloaded tiles");

    $dubiouscount = 0;
    find({ wanted => \&cleantmp, bydepth => 1, no_chdir => 1 }, $testdir)
	if $cleanup;
    ok(!$dubiouscount, "dubious files found");
}


sub countpng
{
    if ($_ =~ /^\d+\.png$/) {
	unlink($_)
	    if $cleanup;
	$pngcount++;
    }
}


sub cleantmp
{
    if (-d $_) {
	rmdir($_)
	    if $_ ne $testdir;
    }
    else {
	diag("dubious file $File::Find::name");
	$dubiouscount++;
	unlink($_);
    }
}


# Local Variables:
# mode: perl
# End:
