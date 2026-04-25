use v5.42;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::Plex',
    VERSION_FROM     => 'lib/WebService/Plex.pm',
    ABSTRACT_FROM    => 'lib/WebService/Plex.pm',
    AUTHOR           => ['Sam Robertson <samr@slriv.com>'],
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.042000',
    PREREQ_PM        => {
        'Carp'         => 0,
        'HTTP::Request'=> 0,
        'JSON::XS'     => 0,
        'LWP::UserAgent'=> 0,
        'URI::Escape'  => 0,
        'builtin'      => 0,
        'experimental' => 0,
    },
    TEST_REQUIRES    => {
        'Test::More'       => 0,
        'Test::Exception'  => 0,
        'Test::MockModule' => 0,
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WebService::Plex' => {
                file    => 'lib/WebService/Plex.pm',
                version => '0.01',
            },
            'WebService::Plex::Server' => {
                file    => 'lib/WebService/Plex/Server.pm',
                version => '0.01',
            },
            'WebService::Plex::Library' => {
                file    => 'lib/WebService/Plex/Library.pm',
                version => '0.01',
            },
        },
    },
);