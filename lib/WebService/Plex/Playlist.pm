use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Playlist {
    use URI::Escape qw(uri_escape);

    field $plex :param;

    # ----------------------------------------------------------- read

    method all (%params)  { $plex->get('/playlists', %params) }
    method get ($id)      { $plex->get("/playlists/$id") }
    method items ($id)    { $plex->get("/playlists/$id/items") }

    # ----------------------------------------------------------- write

    method create (%args) {
        # TODO: verify required params against live server
        #       Plex expects: title, type (audio|video|photo), smart (0|1)
        #       and uri (server://MACHINEID/...library/metadata/KEY,KEY)
        #       The uri format is non-trivial to construct without a MediaContainer helper
        $plex->post('/playlists', %args);
    }

    method update ($id, %args) {
        # TODO: verify which fields are accepted (title, summary observed)
        $plex->put("/playlists/$id", %args);
    }

    method delete ($id) { $plex->delete("/playlists/$id") }

    method add_items ($id, $uri) {
        # TODO: verify uri format -- same server:// scheme as create
        $plex->post("/playlists/$id/items", uri => $uri);
    }

    method remove_item ($id, $playlist_item_id) {
        $plex->delete("/playlists/$id/items/$playlist_item_id");
    }

    method move_item ($id, $playlist_item_id, %params) {
        $plex->put("/playlists/$id/items/$playlist_item_id/move", %params);
    }

    method clear ($id) {
        $plex->delete("/playlists/$id/items");
    }
}

1;
__END__

=head1 NAME

WebService::Plex::Playlist - Playlist read and write operations

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $pl = $plex->playlist;

  my $all   = $pl->all;
  my $one   = $pl->get(12345);
  my $items = $pl->items(12345);

  $pl->delete(12345);

=head1 DESCRIPTION

C<WebService::Plex::Playlist> provides access to Plex playlists: listing,
fetching, creating, updating, deleting, and managing items.

Do not instantiate directly.  Access via C<< $plex->playlist >>.

=head1 METHODS

=head2 all(%params)

Returns all playlists.  Optional C<%params> are forwarded as query parameters
(e.g. C<playlistType =E<gt> 'video'>).

=head2 get($id)

Returns a single playlist by ID.

=head2 items($id)

Returns the items in a playlist.

=head2 create(%args)

Creates a new playlist.  Expected args: C<title>, C<type> (C<audio>, C<video>,
or C<photo>), C<smart> (C<0> or C<1>), and C<uri>.

B<Note:> The C<uri> parameter uses a non-trivial server URI scheme.  See Plex
API documentation for the correct format.

=head2 update($id, %args)

Updates a playlist.  Known accepted fields: C<title>, C<summary>.

=head2 delete($id)

Deletes a playlist.

=head2 add_items($id, $uri)

Adds items to a playlist using the Plex server URI scheme.

=head2 remove_item($id, $playlist_item_id)

Removes a single item by playlist item ID.

=head2 move_item($id, $playlist_item_id, %params)

Moves a playlist item to a different position.  Pass C<< after => $item_id >>
to move after a specific item, or omit to move to the front.

=head2 clear($id)

Removes all items from a playlist (C<DELETE /playlists/$id/items>).

=head1 DEPENDENCIES

Relies on the L<WebService::Plex> connection object passed at construction.
No additional CPAN modules are required beyond those declared by
L<WebService::Plex>.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex>

=item L<WebService::Plex::Collection>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

GNU General Public License, version 3 or later.
See L<https://www.gnu.org/licenses/> for details.

=cut
