use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::MyPlex;

my $fake = FakePlex->new;
my $my   = WebService::Plex::MyPlex->new(plex => $fake);

# --- constants ---

is WebService::Plex::MyPlex::BASE,      'https://plex.tv',                    'BASE constant';
is WebService::Plex::MyPlex::WATCHLIST, 'https://discover.provider.plex.tv',  'WATCHLIST constant';

# --- account ---

$my->account;
is $fake->last_call->{method}, 'get_abs',                    'account uses get_abs';
is $fake->last_call->{path},   'https://plex.tv/api/v2/user','account path';

$my->ping;
is $fake->last_call->{path}, 'https://plex.tv/api/v2/ping', 'ping path';

$my->claim_token;
is $fake->last_call->{path}, 'https://plex.tv/api/claim/token.json', 'claim_token path';

$my->webhooks;
is $fake->last_call->{path}, 'https://plex.tv/api/v2/user/webhooks', 'webhooks path';

# --- home users ---

$my->home_users;
is $fake->last_call->{method}, 'get_abs',                      'home_users uses get_abs';
is $fake->last_call->{path},   'https://plex.tv/api/home/users','home_users path';

$my->switch_home_user(42);
is $fake->last_call->{method}, 'post_abs',                              'switch_home_user uses post_abs';
is $fake->last_call->{path},   'https://plex.tv/api/home/users/42/switch','switch_home_user path';

# --- watchlist ---

$my->watchlist;
is $fake->last_call->{method}, 'get_abs',                                              'watchlist uses get_abs';
is $fake->last_call->{path},   'https://discover.provider.plex.tv/library/sections/watchlist/all',
                                                                                       'watchlist default filter=all';

$my->watchlist('unwatched');
is $fake->last_call->{path}, 'https://discover.provider.plex.tv/library/sections/watchlist/unwatched',
    'watchlist unwatched filter';

$my->watchlist('watched');
is $fake->last_call->{path}, 'https://discover.provider.plex.tv/library/sections/watchlist/watched',
    'watchlist watched filter';

$my->watchlist('all', sort => 'titleSort');
is $fake->last_call->{params}{sort}, 'titleSort', 'watchlist forwards extra params';

$my->add_to_watchlist(12345);
is $fake->last_call->{method}, 'put_abs', 'add_to_watchlist uses put_abs';
like $fake->last_call->{path}, qr{addToWatchlist},     'add_to_watchlist path';
like $fake->last_call->{path}, qr{ratingKey=12345},    'add_to_watchlist ratingKey';

$my->add_to_watchlist('tt0816692');
like $fake->last_call->{path}, qr{ratingKey=tt0816692}, 'add_to_watchlist string key';

$my->remove_from_watchlist(12345);
is $fake->last_call->{method}, 'put_abs', 'remove_from_watchlist uses put_abs';
like $fake->last_call->{path}, qr{removeFromWatchlist}, 'remove_from_watchlist path';
like $fake->last_call->{path}, qr{ratingKey=12345},     'remove_from_watchlist ratingKey';

# --- users / devices / resources ---

$my->users;
is $fake->last_call->{method}, 'get_abs',                    'users uses get_abs';
is $fake->last_call->{path},   'https://plex.tv/api/users/', 'users path';

$my->devices;
is $fake->last_call->{path}, 'https://plex.tv/devices.xml', 'devices path';

$my->resources;
like $fake->last_call->{path}, qr{plex\.tv/api/v2/resources}, 'resources path';

# --- webhook management ---

$my->add_webhook('https://example.com/hook');
is $fake->last_call->{method},         'post_abs',                              'add_webhook uses post_abs';
is $fake->last_call->{path},           'https://plex.tv/api/v2/user/webhooks',  'add_webhook path';
is $fake->last_call->{params}{url},    'https://example.com/hook',              'add_webhook url param';

$my->delete_webhook('https://example.com/hook');
is $fake->last_call->{method},         'delete_abs',                            'delete_webhook uses delete_abs';

# --- geo / network ---

$my->public_ip;
is $fake->last_call->{path}, 'https://plex.tv/:/ip', 'public_ip path';

$my->geoip('1.2.3.4');
like $fake->last_call->{path},               qr{plex\.tv/api/v2/geoip}, 'geoip path';
is $fake->last_call->{params}{ip_address},   '1.2.3.4',                 'geoip ip_address param';

done_testing;
