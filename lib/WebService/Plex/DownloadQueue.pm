use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::DownloadQueue {
    field $plex :param;

    method create (%params) {
        $plex->post('/downloadQueue', %params);
    }

    method get ($queue_id) {
        $plex->get("/downloadQueue/$queue_id");
    }

    method add ($queue_id, %params) {
        $plex->post("/downloadQueue/$queue_id/add", %params);
    }

    method items ($queue_id, %params) {
        $plex->get("/downloadQueue/$queue_id/items", %params);
    }

    method get_item ($queue_id, $item_id) {
        $plex->get("/downloadQueue/$queue_id/items/$item_id");
    }

    method delete_item ($queue_id, $item_id) {
        $plex->delete("/downloadQueue/$queue_id/items/$item_id");
    }

    method item_media ($queue_id, $item_id, %params) {
        $plex->get("/downloadQueue/$queue_id/item/$item_id/media", %params);
    }

    method item_decision ($queue_id, $item_id, %params) {
        $plex->get("/downloadQueue/$queue_id/item/$item_id/decision", %params);
    }

    method restart_item ($queue_id, $item_id) {
        $plex->post("/downloadQueue/$queue_id/items/$item_id/restart");
    }
}

1;
__END__

=head1 NAME

WebService::Plex::DownloadQueue - Download queue management for Plex Media Server

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $dq = $plex->download_queue;
  $dq->create(name => 'My Queue');
  $dq->items($queue_id);
  $dq->restart_item($queue_id, $item_id);

=head1 DESCRIPTION

C<WebService::Plex::DownloadQueue> provides a thin wrapper around the Plex
C</downloadQueue> API for creating and managing download queues and queue items.

=head1 METHODS

=head2 create(%params)

Creates a download queue.

=head2 get($queue_id)

Returns details for a download queue.

=head2 add($queue_id, %params)

Adds items to a download queue.

=head2 items($queue_id, %params)

Returns the items for a download queue.

=head2 get_item($queue_id, $item_id)

Returns a single download queue item.

=head2 delete_item($queue_id, $item_id)

Removes an item from a download queue.

=head2 item_media($queue_id, $item_id, %params)

Returns streaming media metadata for a queue item.

=head2 item_decision($queue_id, $item_id, %params)

Returns the decision document for a queue item.

=head2 restart_item($queue_id, $item_id)

Restarts a download queue item.
