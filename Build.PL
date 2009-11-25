use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Nagios::Passive',
    license             => 'perl',
    dist_author         => 'Danijel Tasov <data@cpan.org>',
    dist_version_from   => 'lib/Nagios/Passive.pm',
    dist_abstract       => 'drop check results into nagios\' spool dir',
    create_license      => 1,
    requires => {
        'Test::More' => 0,
        'File::Temp' => 0,
        'version'    => 0,
        'Moose'      => '0.92',
        'Nagios::Plugin' => 0,
	'perl'       => '5.8.0',
    },
    add_to_cleanup      => [ 'Nagios-Passive-*' ],
);

$builder->create_build_script();
