use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::PlayQueue;

my $fake = FakePlex->new;
my $pq   = WebService::Plex::PlayQueue->new(plex => $fake);

$pq->create(type => 'video', uri => 'server://1/movie/2');
is $fake->last_call->{method}, 'post',          'create uses POST';
like $fake->last_call->{path}, qr{^/playQueues\b}, 'create path';

$pq->get(42);
is $fake->last_call->{method}, 'get', 'get uses GET';
is $fake->last_call->{path}, '/playQueues/42', 'get path';

$pq->items(42, start => 0, size => 10);
is $fake->last_call->{path}, '/playQueues/42/items?size=10&start=0', 'items query path';

$pq->update(42, title => 'New Title');
is $fake->last_call->{method}, 'put', 'update uses PUT';
is $fake->last_call->{path}, '/playQueues/42?title=New%20Title', 'update path';

$pq->delete_items(42, uri => 'server://1/movie/2');
is $fake->last_call->{method}, 'delete', 'delete_items uses DELETE';
is $fake->last_call->{path}, '/playQueues/42/items?uri=server%3A%2F%2F1%2Fmovie%2F2', 'delete_items path';

$pq->remove_item(42, 7);
is $fake->last_call->{method}, 'delete', 'remove_item uses DELETE';
is $fake->last_call->{path}, '/playQueues/42/items/7', 'remove_item path';

$pq->move_item(42, 7, newPosition => 1);
is $fake->last_call->{method}, 'put', 'move_item uses PUT';
is $fake->last_call->{path}, '/playQueues/42/items/7/move?newPosition=1', 'move_item path';

$pq->reset(42);
is $fake->last_call->{path}, '/playQueues/42/reset', 'reset path';

$pq->shuffle(42);
is $fake->last_call->{path}, '/playQueues/42/shuffle', 'shuffle path';

$pq->unshuffle(42);
is $fake->last_call->{path}, '/playQueues/42/unshuffle', 'unshuffle path';

# --- clear ---

$pq->clear(42);
is $fake->last_call->{method}, 'delete',              'clear uses DELETE';
is $fake->last_call->{path},   '/playQueues/42/items','clear path';

# --- refresh ---

$pq->refresh(42);
is $fake->last_call->{method}, 'get',             'refresh uses GET';
is $fake->last_call->{path},   '/playQueues/42',  'refresh path';

# --- from_station_key ---

$pq->from_station_key('/library/metadata/500/station/abc');
is $fake->last_call->{method},  'post',              'from_station_key uses POST';
like $fake->last_call->{path},  qr{^/playQueues\b},  'from_station_key path';
is $fake->last_call->{params}{isStation},  1,             'from_station_key isStation=1';
is $fake->last_call->{params}{type},       'audio',       'from_station_key type=audio';

done_testing;
