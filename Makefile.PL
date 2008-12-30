use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	     => 'Geo::OSM::Tiles',
    ABSTRACT_FROM    => 'lib/Geo/OSM/Tiles.pm', 
    AUTHOR	     => 'Rolf Krahl <rolf@rotkraut.de>', 
    VERSION_FROM     => 'lib/Geo/OSM/Tiles.pm', 
    PREREQ_PM	     => { 
	Math::Trig     => 0,
	LWP            => 0, 
	Getopt::Long   => 0,
	File::Path     => 0,
	File::Basename => 0,
	Cwd            => 0,
    }, 
    EXE_FILES	     => [ 'downloadosmtiles.pl' ],
    PM		     => { 'lib/Geo/OSM/Tiles.pm' => '$(INST_LIBDIR)/Tiles.pm'}, 
);
