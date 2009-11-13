use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Nagios::Spool::Writer',
    license             => 'perl',
    dist_author         => 'Danijel Tašov <dt@korn.shell.la>',
    dist_version_from   => 'lib/Nagios/Spool/Writer.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Nagios-Spool-Writer-*' ],
);

$builder->create_build_script();
