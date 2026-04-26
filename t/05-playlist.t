use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Playlist;

my $fake = FakePlex->new;
my $pl   = WebService::Plex::Playlist->new(plex => $fake);

# --- read ---

$pl->all;
is $fake->last_call->{method}, 'get',        'all uses GET';
is $fake->last_call->{path},   '/playlists', 'all path';

$pl->all(playlistType => 'video');
is $fake->last_call->{params}{playlistType}, 'video', 'all forwards params';

$pl->get(42);
is $fake->last_call->{method}, 'get',          'get uses GET';
is $fake->last_call->{path},   '/playlists/42','get path';

$pl->items(42);
is $fake->last_call->{method}, 'get',                'items uses GET';
is $fake->last_call->{path},   '/playlists/42/items','items path';

# --- write ---

$pl->create(title => 'My List', type => 'video', smart => 0);
is $fake->last_call->{method},           'post',            'create uses POST';
like $fake->last_call->{path},           qr{^/playlists\b}, 'create path';
is $fake->last_call->{params}{title},    'My List',         'create title param';
is $fake->last_call->{params}{type},     'video',           'create type param';
is $fake->last_call->{params}{smart},    0,                 'create smart param';

$pl->create(title => 'Smart Mix', type => 'audio', smart => 1);
is $fake->last_call->{params}{smart},    1,            'create smart=1 path';

$pl->update(42, title => 'Renamed');
is $fake->last_call->{method}, 'put',                  'update uses PUT';
like $fake->last_call->{path}, qr{^/playlists/42\?},   'update path';
like $fake->last_call->{path}, qr{title=Renamed},      'update title in query';

$pl->update(42, title => 'Has Spaces & Symbols');
like $fake->last_call->{path}, qr{Has%20Spaces},       'update URI-encodes spaces';
like $fake->last_call->{path}, qr{%26},                'update URI-encodes ampersand';

$pl->delete(42);
is $fake->last_call->{method}, 'delete',       'delete uses DELETE';
is $fake->last_call->{path},   '/playlists/42','delete path';

$pl->add_items(42, 'server://abc/library/metadata/1');
is $fake->last_call->{method},      'post',                                'add_items uses POST';
like $fake->last_call->{path},      qr{^/playlists/42/items\b},            'add_items path';
is $fake->last_call->{params}{uri}, 'server://abc/library/metadata/1',     'add_items uri param';

$pl->remove_item(42, 99);
is $fake->last_call->{method}, 'delete',                     'remove_item uses DELETE';
is $fake->last_call->{path},   '/playlists/42/items/99',     'remove_item path includes item ID';

# --- move_item ---

$pl->move_item(42, 99);
is $fake->last_call->{method}, 'put',                              'move_item uses PUT';
is $fake->last_call->{path},   '/playlists/42/items/99/move',      'move_item path';

$pl->move_item(42, 99, after => 77);
is $fake->last_call->{params}{after}, 77, 'move_item after param';

# --- clear ---

$pl->clear(42);
is $fake->last_call->{method}, 'delete',               'clear uses DELETE';
is $fake->last_call->{path},   '/playlists/42/items',  'clear path';

done_testing;
