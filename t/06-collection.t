use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Collection;

my $fake = FakePlex->new;
my $col  = WebService::Plex::Collection->new(plex => $fake);

# --- read ---

$col->all(1);
is $fake->last_call->{method}, 'get',                              'all uses GET';
is $fake->last_call->{path},   '/library/sections/1/collections',  'all path';

$col->get(42);
is $fake->last_call->{method}, 'get',                         'get uses GET';
is $fake->last_call->{path},   '/library/collections/42',     'get path';

$col->items(42);
is $fake->last_call->{method}, 'get',                              'items uses GET';
is $fake->last_call->{path},   '/library/collections/42/children', 'items path';

# --- write ---

$col->create(1, title => 'Sci-Fi', type => 1, smart => 0);
is $fake->last_call->{method},            'post',                'create uses POST';
is $fake->last_call->{path},              '/library/collections', 'create path';
is $fake->last_call->{params}{sectionId}, 1,                     'create sectionId param';
is $fake->last_call->{params}{title},     'Sci-Fi',              'create title param';
is $fake->last_call->{params}{type},      1,                     'create type param';
is $fake->last_call->{params}{smart},     0,                     'create smart=0 param';

$col->create(1, title => 'Smart Sci-Fi', type => 1, smart => 1);
is $fake->last_call->{params}{smart},     1,                     'create smart=1 path';

$col->update(42, title => 'Sci-Fi Updated');
is $fake->last_call->{method}, 'put',                          'update uses PUT';
like $fake->last_call->{path}, qr{^/library/collections/42\?}, 'update path';
like $fake->last_call->{path}, qr{title=Sci-Fi},               'update title in query';

$col->delete(42);
is $fake->last_call->{method}, 'delete',                    'delete uses DELETE';
is $fake->last_call->{path},   '/library/collections/42',   'delete path';

$col->add_items(42, 100, 101, 102);
is $fake->last_call->{method},        'post',                          'add_items uses POST';
is $fake->last_call->{path},          '/library/collections/42/items', 'add_items path';
like $fake->last_call->{params}{uri}, qr{100},                         'add_items first key';
like $fake->last_call->{params}{uri}, qr{102},                         'add_items last key';

$col->add_items(42, 999);
is $fake->last_call->{params}{uri}, '999', 'add_items single key';

$col->remove_items(42, 100, 101);
is $fake->last_call->{method}, 'delete',                             'remove_items uses DELETE';
like $fake->last_call->{path}, qr{^/library/collections/42/items},  'remove_items path';
like $fake->last_call->{path}, qr{uri=},                             'remove_items uri param';

$col->remove_items(42, 999);
like $fake->last_call->{path}, qr{uri=999}, 'remove_items single key';

# --- move_item ---

$col->move_item(42, 100);
is $fake->last_call->{method}, 'put',                                    'move_item uses PUT';
is $fake->last_call->{path},   '/library/collections/42/items/100/move', 'move_item path';

$col->move_item(42, 100, after => 99);
is $fake->last_call->{params}{after}, 99, 'move_item after param';

# --- mode_update ---

$col->mode_update(42, 0);
is $fake->last_call->{method},                 'put',                              'mode_update uses PUT';
like $fake->last_call->{path},                 qr{^/library/collections/42/mode},  'mode_update path';
is $fake->last_call->{params}{collectionMode}, 0,                                  'mode_update param';

# --- sort_update ---

$col->sort_update(42, 2);
is $fake->last_call->{method},                 'put',                              'sort_update uses PUT';
like $fake->last_call->{path},                 qr{^/library/collections/42/sort},  'sort_update path';
is $fake->last_call->{params}{collectionSort}, 2,                                  'sort_update param';

# --- visibility ---

$col->visibility(42);
is $fake->last_call->{method}, 'get',                                      'visibility uses GET';
is $fake->last_call->{path},   '/library/collections/42/visibility',       'visibility path';

done_testing;
