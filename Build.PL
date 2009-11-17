use strict;
use warnings;
use utf8;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Nagios::Spool::Writer',
    license             => 'perl',
    dist_author         => 'Danijel Tašov <data@cpan.org>',
    dist_version_from   => 'lib/Nagios/Spool/Writer.pm',
    dist_abstract       => 'drop check results into nagios\' spool dir',
    requires => {
        'Test::More' => 0,
        'File::Temp' => 0,
        'version'    => 0,
        'Moose'      => '0.92',
        'Nagios::Plugin' => 0,
         # may be it runs with older versions of perl, but I don't support them
        'perl'       => '5.8.8',
    },
    add_to_cleanup      => [ 'Nagios-Spool-Writer-*' ],
);

$builder->create_build_script();
