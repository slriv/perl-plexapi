use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Alert;

my $fake  = FakePlex->new(baseurl => 'http://plex.local:32400', token => 'mytoken');
my $alert = WebService::Plex::Alert->new(plex => $fake);

# --- ws_url construction ---

my $url = $alert->ws_url;
like $url, qr{^ws://plex\.local:32400},         'ws_url uses ws:// for http baseurl';
like $url, qr{/:/websockets/notifications},      'ws_url has correct path';
like $url, qr{X-Plex-Token=mytoken},             'ws_url includes token';

# HTTPS baseurl should produce wss:// URL
my $https_fake  = FakePlex->new(baseurl => 'https://secure.plex:32400', token => 'tok');
my $https_alert = WebService::Plex::Alert->new(plex => $https_fake);
like $https_alert->ws_url, qr{^wss://}, 'ws_url uses wss:// for https baseurl';

# --- listen requires AnyEvent ---

use_ok 'AnyEvent';
use_ok 'AnyEvent::WebSocket::Client';
can_ok $alert, 'listen';

done_testing;
