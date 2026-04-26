use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Photo {
    field $plex :param;

    # ----------------------------------------------------------- section browsing
    # Photo sections use type=13 (photoalbum) and type=14 (photo).

    method albums ($section_key, %params) {
        $plex->get("/library/sections/$section_key/all", type => 13, %params);
    }

    method album ($rating_key) {
        $plex->get("/library/metadata/$rating_key");
    }

    method photos ($album_key, %params) {
        $plex->get("/library/metadata/$album_key/children", %params);
    }

    method clips ($album_key, %params) {
        $plex->get("/library/metadata/$album_key/children", type => 12, %params);
    }

    method search ($section_key, $query, %params) {
        $plex->get("/library/sections/$section_key/search",
            query => $query,
            type  => 13,
            %params,
        );
    }

    method recently_added ($section_key, %params) {
        $plex->get("/library/sections/$section_key/recentlyAdded", type => 14, %params);
    }

    # ----------------------------------------------------------- transcoding

    method transcode (%params) {
        $plex->get('/photo/:/transcode', %params);
    }
}

1;
__END__

=head1 NAME

WebService::Plex::Photo - Plex photo library browsing and transcoding

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $photo = $plex->photo;

  my $albums = $photo->albums(4);
  my $photos = $photo->photos($album_key);
  my $clips  = $photo->clips($album_key);

  $photo->transcode(url => $image_url, maxWidth => 400);

=head1 DESCRIPTION

C<WebService::Plex::Photo> provides access to Plex photo library sections
(album browsing, photo listing, clip listing) and the photo transcoding
endpoint.

Photo sections use Plex media type codes: C<13> for photo albums,
C<14> for individual photos.

=head1 METHODS

=head2 albums($section_key, %params)

Returns photo albums in a library section (type=13).

=head2 album($rating_key)

Returns a single photo album by rating key.

=head2 photos($album_key, %params)

Returns photos inside an album.

=head2 clips($album_key, %params)

Returns video clips inside an album (type=12).

=head2 search($section_key, $query, %params)

Searches for photo albums within a section.

=head2 recently_added($section_key, %params)

Returns recently added photos in a section.

=head2 transcode(%params)

Transcodes/resizes a photo via C<GET /photo/:/transcode>.  Common params:
C<url>, C<maxWidth>, C<maxHeight>, C<quality>.

=head1 DEPENDENCIES

Relies on the L<WebService::Plex> connection object passed at construction.

=head1 SEE ALSO

L<WebService::Plex>, L<WebService::Plex::Library>

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

GNU General Public License, version 3 or later.
See L<https://www.gnu.org/licenses/> for details.

=cut
