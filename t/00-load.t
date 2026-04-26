use v5.42;
use Test::More;

BEGIN {
    use_ok('WebService::Plex');
    use_ok('WebService::Plex::Server');
    use_ok('WebService::Plex::Library');
    use_ok('WebService::Plex::Playlist');
    use_ok('WebService::Plex::Collection');
    use_ok('WebService::Plex::Video');
    use_ok('WebService::Plex::Audio');
    use_ok('WebService::Plex::MyPlex');
    use_ok('WebService::Plex::Client');
    use_ok('WebService::Plex::Alert');
}

done_testing;