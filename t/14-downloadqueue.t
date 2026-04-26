use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::DownloadQueue;

my $fake = FakePlex->new;
my $dq   = WebService::Plex::DownloadQueue->new(plex => $fake);

$dq->create(name => 'My Queue');
is $fake->last_call->{method}, 'post',                   'create uses POST';
like $fake->last_call->{path}, qr{^/downloadQueue\b},    'create path';

$dq->get(42);
is $fake->last_call->{method}, 'get',                'get uses GET';
is $fake->last_call->{path},   '/downloadQueue/42',  'get path';

$dq->add(42, uri => 'server://1/album/2');
is $fake->last_call->{method}, 'post',                       'add uses POST';
like $fake->last_call->{path}, qr{^/downloadQueue/42/add\b}, 'add path';

$dq->items(42, includeExtras => 1);
is $fake->last_call->{method}, 'get', 'items uses GET';
is $fake->last_call->{path}, '/downloadQueue/42/items?includeExtras=1', 'items path + params';

$dq->get_item(42, 7);
is $fake->last_call->{path}, '/downloadQueue/42/items/7', 'get_item path';

$dq->delete_item(42, 7);
is $fake->last_call->{method}, 'delete', 'delete_item uses DELETE';
is $fake->last_call->{path}, '/downloadQueue/42/items/7', 'delete_item path';

$dq->item_media(42, 7, accept => 'video/mp4');
is $fake->last_call->{path}, '/downloadQueue/42/item/7/media?accept=video%2Fmp4', 'item_media query path';

$dq->item_decision(42, 7);
is $fake->last_call->{path}, '/downloadQueue/42/item/7/decision', 'item_decision path';

$dq->restart_item(42, 7);
is $fake->last_call->{method}, 'post',                                      'restart_item uses POST';
like $fake->last_call->{path}, qr{^/downloadQueue/42/items/7/restart\b},    'restart_item path';

done_testing;
