use v5.42;
use ExtUtils::MakeMaker;

# Custom target: prove t/integration against a live Docker test server.
# Usage: make test_integration
#   (requires docker compose up -d && perl tools/bootstrap-test-server.pl first)
{
    package MY;
    sub top_targets {
    my $self = shift;
    my $text = $self->SUPER::top_targets(@_);
    my $help = <<'HELP';
help :
	@echo "WebService::Plex -- available make targets"
	@echo ""
	@echo "  Build and test:"
	@echo "    make                   Build (same as make all)"
	@echo "    make test              Run unit tests (no server needed)"
	@echo "    make test_integration  Run integration tests against live Plex"
	@echo "    make distcheck         Verify MANIFEST matches files on disk"
	@echo ""
	@echo "  Install:"
	@echo "    make install           Install to site Perl"
	@echo "    make uninstall         Remove installed files"
	@echo "    make dist              Build .tar.gz for CPAN upload"
	@echo ""
	@echo "  Docker / Plex test server:"
	@echo "    make plex_start        docker compose up -d"
	@echo "    make plex_stop         docker compose down"
	@echo "    make plex_reset        Wipe Plex config for a clean re-bootstrap"
	@echo ""
	@echo "  Clean:"
	@echo "    make clean             Remove build artifacts"
	@echo "    make realclean         Remove build artifacts and generated Makefile"
	@echo ""
	@echo "  Tip: perl tools/bootstrap-test-server.pl handles full Docker setup"

HELP
    $text =~ s/^help\b[^\n]*\n\t[^\n]*\n/$help/m;
    return $text;
    }
}

sub MY::postamble {
    return <<'MAKE';
test_integration :
	prove -I lib -I t/integration/lib t/integration/*.t

plex_start :
	docker compose up -d
	@echo "Run: perl tools/bootstrap-test-server.pl"

plex_stop :
	docker compose down

plex_reset :
	docker compose down -v
	rm -rf plex-test-data

# When INSTALL_BASE is used, these variables must be redirected to the
# install-base paths so `make uninstall` removes the correct packlist.
UNINSTALL := $(ABSPERLRUN) -MExtUtils::Install -e 'uninstall(shift,1,0);' --
SITEARCHEXP := $(INSTALLSITEARCH)
VENDORARCHEXP := $(INSTALLVENDORARCH)
PERL_ARCHLIB := $(INSTALLPRIVLIB)
MAKE
}

WriteMakefile(
    NAME             => 'WebService::Plex',
    VERSION_FROM     => 'lib/WebService/Plex.pm',
    ABSTRACT_FROM    => 'lib/WebService/Plex.pm',
    AUTHOR           => ['Sam Robertson <samr@slriv.com>'],
    LICENSE          => 'gpl_3',
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
        'Test::MockModule'    => 0,
        'Test::LWP::UserAgent'=> 0,
    },
    clean            => { FILES => '*.tar.gz *.bak' },
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
            'WebService::Plex::Playlist' => {
                file    => 'lib/WebService/Plex/Playlist.pm',
                version => '0.01',
            },
            'WebService::Plex::Collection' => {
                file    => 'lib/WebService/Plex/Collection.pm',
                version => '0.01',
            },
            'WebService::Plex::DownloadQueue' => {
                file    => 'lib/WebService/Plex/DownloadQueue.pm',
                version => '0.01',
            },
            'WebService::Plex::LiveTV' => {
                file    => 'lib/WebService/Plex/LiveTV.pm',
                version => '0.01',
            },
            'WebService::Plex::Photo' => {
                file    => 'lib/WebService/Plex/Photo.pm',
                version => '0.01',
            },
            'WebService::Plex::PlayQueue' => {
                file    => 'lib/WebService/Plex/PlayQueue.pm',
                version => '0.01',
            },
            'WebService::Plex::Services' => {
                file    => 'lib/WebService/Plex/Services.pm',
                version => '0.01',
            },
            'WebService::Plex::Video' => {
                file    => 'lib/WebService/Plex/Video.pm',
                version => '0.01',
            },
            'WebService::Plex::Audio' => {
                file    => 'lib/WebService/Plex/Audio.pm',
                version => '0.01',
            },
            'WebService::Plex::MyPlex' => {
                file    => 'lib/WebService/Plex/MyPlex.pm',
                version => '0.01',
            },
            'WebService::Plex::Client' => {
                file    => 'lib/WebService/Plex/Client.pm',
                version => '0.01',
            },
            'WebService::Plex::Alert' => {
                file    => 'lib/WebService/Plex/Alert.pm',
                version => '0.01',
            },
        },
    },
);