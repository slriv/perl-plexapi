use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::PlayQueue {
    field $plex :param;

    method create (%params) {
        $plex->post('/playQueues', %params);
    }

    method get ($id) {
        $plex->get("/playQueues/$id");
    }

    method items ($id, %params) {
        $plex->get("/playQueues/$id/items", %params);
    }

    method update ($id, %params) {
        $plex->put("/playQueues/$id", %params);
    }

    method delete_items ($id, %params) {
        $plex->delete("/playQueues/$id/items", %params);
    }

    method remove_item ($id, $play_queue_item_id) {
        $plex->delete("/playQueues/$id/items/$play_queue_item_id");
    }

    method move_item ($id, $play_queue_item_id, %params) {
        $plex->put("/playQueues/$id/items/$play_queue_item_id/move", %params);
    }

    method reset ($id, %params) {
        $plex->put("/playQueues/$id/reset", %params);
    }

    method shuffle ($id, %params) {
        $plex->put("/playQueues/$id/shuffle", %params);
    }

    method unshuffle ($id, %params) {
        $plex->put("/playQueues/$id/unshuffle", %params);
    }

    method clear ($id) {
        $plex->delete("/playQueues/$id/items");
    }

    method refresh ($id) {
        $plex->get("/playQueues/$id");
    }

    method from_station_key ($station_key, %params) {
        $plex->post('/playQueues',
            type      => 'audio',
            uri       => $station_key,
            isStation => 1,
            %params,
        );
    }
}

1;
__END__

=head1 NAME

WebService::Plex::PlayQueue - Plex play queue management

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $pq = $plex->play_queue;
  my $queue = $pq->create(type => 'video', uri => $uri);
  $pq->shuffle($queue->{MediaContainer}{playQueueID});
  $pq->from_station_key($station_key);

=head1 DESCRIPTION

C<WebService::Plex::PlayQueue> wraps the Plex C</playQueues> API to manage
play queue creation, updates, and queue item manipulation.

=head1 METHODS

=head2 create(%params)

Creates a new play queue (C<POST /playQueues>).

=head2 get($id)

Returns a play queue by ID.

=head2 refresh($id)

Re-fetches the play queue to pick up server-side changes (C<GET /playQueues/$id>).

=head2 items($id, %params)

Returns the items in a play queue.

=head2 update($id, %params)

Updates play queue parameters.

=head2 delete_items($id, %params)

Removes items from a play queue by criteria.

=head2 remove_item($id, $play_queue_item_id)

Removes a single item from the play queue.

=head2 move_item($id, $play_queue_item_id, %params)

Moves a play queue item.

=head2 clear($id)

Removes all items from the play queue (C<DELETE /playQueues/$id/items>).

=head2 reset($id, %params)

Resets the play queue.

=head2 shuffle($id, %params)

Shuffles the play queue.

=head2 unshuffle($id, %params)

Unshuffles the play queue.

=head2 from_station_key($station_key, %params)

Creates a play queue from a radio station key
(C<POST /playQueues?isStation=1>).  The station key is obtained from
C<< $plex->audio->station($artist_key) >>.
