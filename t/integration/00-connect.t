use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";
use PlexIntegration qw(plex_or_skip);

my $plex = plex_or_skip();

my $data = $plex->server->identity;
ok $data, 'identity returns data';

my $mc = $data->{MediaContainer};
ok $mc,                           'identity has MediaContainer';
ok $mc->{machineIdentifier},      'machineIdentifier present';
ok $mc->{version},                'version present';
like $mc->{version}, qr/^\d+\.\d+/, 'version looks like a version number';

done_testing;
