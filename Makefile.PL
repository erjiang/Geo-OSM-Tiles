use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	     => 'Geo::OSM::Tiles',
    ABSTRACT_FROM    => 'lib/Geo/OSM/Tiles.pm', 
    AUTHOR	     => 'Rolf Krahl <rolf@rotkraut.de>', 
    VERSION_FROM     => 'lib/Geo/OSM/Tiles.pm', 
    PREREQ_PM	     => { LWP => 0, }, 
    EXE_FILES	     => [ 'downloadosmtiles.pl' ],
    PM		     => { 'lib/Geo/OSM/Tiles.pm' => '$(INST_LIBDIR)/Tiles.pm'}, 
);
