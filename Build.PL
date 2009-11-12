use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Nagios::Passive::Spool',
    license             => 'perl',
    dist_author         => 'Danijel Tašov <dt@korn.shell.la>',
    dist_version_from   => 'lib/Nagios/Passive/Spool.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Nagios-Passive-Spool-*' ],
);

$builder->create_build_script();
