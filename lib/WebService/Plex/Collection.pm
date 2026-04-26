use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Collection {
    use URI::Escape qw(uri_escape);

    field $plex :param;

    # ----------------------------------------------------------- read

    method all ($section_key) {
        $plex->get("/library/sections/$section_key/collections");
    }

    method get ($rating_key) {
        $plex->get("/library/collections/$rating_key");
    }

    method items ($rating_key) {
        $plex->get("/library/collections/$rating_key/children");
    }

    # ----------------------------------------------------------- write

    method create ($section_key, %args) {
        # TODO: verify required params against live server
        #       Plex expects: title, type (1=movie,2=show,8=music,etc), smart (0|1), sectionId
        $plex->post('/library/collections', sectionId => $section_key, %args);
    }

    method update ($rating_key, %args) {
        # TODO: verify accepted fields (title, summary, titleSort observed)
        $plex->put("/library/collections/$rating_key", %args);
    }

    method delete ($rating_key) {
        $plex->delete("/library/collections/$rating_key");
    }

    method add_items ($rating_key, @item_rating_keys) {
        # TODO: verify param name and whether multiple keys can be comma-joined
        my $uri = join(',', @item_rating_keys);
        $plex->post("/library/collections/$rating_key/items", uri => $uri);
    }

    method remove_items ($rating_key, @item_rating_keys) {
        my $uri = join(',', @item_rating_keys);
        $plex->delete("/library/collections/$rating_key/items", uri => $uri);
    }

    method move_item ($rating_key, $item_id, %params) {
        $plex->put("/library/collections/$rating_key/items/$item_id/move", %params);
    }

    method mode_update ($rating_key, $mode) {
        # mode: 0=hide,1=show,2=hideInLibrary
        $plex->put("/library/collections/$rating_key/mode", collectionMode => $mode);
    }

    method sort_update ($rating_key, $sort) {
        # sort: 0=release,1=alpha,2=custom
        $plex->put("/library/collections/$rating_key/sort", collectionSort => $sort);
    }

    method visibility ($rating_key) {
        $plex->get("/library/collections/$rating_key/visibility");
    }
}

1;
__END__

=head1 NAME

WebService::Plex::Collection - Collection read and write operations

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $col = $plex->collection;

  my $all   = $col->all(1);
  my $one   = $col->get(12345);
  my $items = $col->items(12345);

  $col->delete(12345);

=head1 DESCRIPTION

C<WebService::Plex::Collection> provides access to Plex collections: listing,
fetching, creating, updating, deleting, and managing collection items.

Do not instantiate directly.  Access via C<< $plex->collection >>.

=head1 METHODS

=head2 all($section_key)

Returns all collections in the library section identified by C<$section_key>.

=head2 get($rating_key)

Returns a single collection by rating key.

=head2 items($rating_key)

Returns the items in a collection.

=head2 create($section_key, %args)

Creates a new collection.  C<$section_key> is the library section ID.
Expected args: C<title>, C<type> (numeric media type), C<smart> (C<0> or C<1>).

=head2 update($rating_key, %args)

Updates a collection.  Known accepted fields: C<title>, C<summary>,
C<titleSort>.

=head2 delete($rating_key)

Deletes a collection.

=head2 add_items($rating_key, @item_rating_keys)

Adds one or more items to a collection by their rating keys.

=head2 remove_items($rating_key, @item_rating_keys)

Removes one or more items from a collection.

=head2 move_item($rating_key, $item_id, %params)

Moves a collection item.  Pass C<< after => $item_id >> to position after
a specific item.

=head2 mode_update($rating_key, $mode)

Sets the collection display mode: C<0>=hide, C<1>=show, C<2>=hideInLibrary.

=head2 sort_update($rating_key, $sort)

Sets the collection sort order: C<0>=release, C<1>=alpha, C<2>=custom.

=head2 visibility($rating_key)

Returns the visibility settings for a collection.

=head1 DEPENDENCIES

Relies on the L<WebService::Plex> connection object passed at construction.
No additional CPAN modules are required beyond those declared by
L<WebService::Plex>.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex>

=item L<WebService::Plex::Playlist>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

GNU General Public License, version 3 or later.
See L<https://www.gnu.org/licenses/> for details.

=cut
