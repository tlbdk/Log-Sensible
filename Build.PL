use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Misc::Sensible',
    license           => 'perl',
    dist_author       => 'Troels Liebe Bentsen <troels@it-kartellet.dk>',
    dist_version_from => 'lib/Log/Sensible.pm',
    create_readme     => 1,
    create_makefile_pl => 'passthrough',
    requires => {
        'perl'   => '>= 5.8.0',
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup => [ 
        'Log-Sensible-*',
        'Makefile',
        'blib',
    ],
);

$builder->create_build_script();
