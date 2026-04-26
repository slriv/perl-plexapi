use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Video {
    field $plex :param;

    # Plex media type codes for video content
    use constant {
        TYPE_MOVIE   => 1,
        TYPE_SHOW    => 2,
        TYPE_SEASON  => 3,
        TYPE_EPISODE => 4,
        TYPE_CLIP    => 12,
    };

    # ----------------------------------------------------------- browse

    method movies ($section_key, %params) {
        $plex->get("/library/sections/$section_key/all", type => TYPE_MOVIE, %params);
    }

    method shows ($section_key, %params) {
        $plex->get("/library/sections/$section_key/all", type => TYPE_SHOW, %params);
    }

    method seasons ($show_key, %params) {
        $plex->get("/library/metadata/$show_key/children", %params);
    }

    method episodes ($season_key, %params) {
        $plex->get("/library/metadata/$season_key/children", %params);
    }

    method all_episodes ($show_key, %params) {
        $plex->get("/library/metadata/$show_key/allLeaves", %params);
    }

    # ----------------------------------------------------------- search

    method search ($query, %params) {
        # Pass mediatype => 'movie', 'show', or 'episode' to influence results.
        # Verified: 'movie','show','episode','video' all accepted by live server.
        # Note: mediatype does not filter hubs -- all hub types are returned;
        # it affects scoring/ranking of items within each hub.
        $plex->get('/hubs/search', query => $query, %params);
    }

    # ----------------------------------------------------------- maintenance

    method analyze ($rating_key) {
        $plex->put("/library/metadata/$rating_key/analyze");
    }

    method optimize ($rating_key, %params) {
        $plex->put("/library/metadata/$rating_key/optimize", %params);
    }

    # ----------------------------------------------------------- subtitles

    method search_subtitles ($rating_key, %params) {
        $params{language}        //= 'en';
        $params{hearingImpaired} //= 0;
        $params{forced}          //= 0;
        $plex->get("/library/metadata/$rating_key/subtitles", %params);
    }

    method download_subtitle ($rating_key, $subtitle_key) {
        $plex->put("/library/metadata/$rating_key/subtitles", key => $subtitle_key);
    }

    method remove_subtitle ($subtitle_stream_key) {
        $plex->delete($subtitle_stream_key);
    }
}

1;
__END__

=head1 NAME

WebService::Plex::Video - Video library browsing: Movies, Shows, Seasons, Episodes

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $video = $plex->video;

  # Browse by type
  my $movies   = $video->movies(1);
  my $shows    = $video->shows(1);
  my $seasons  = $video->seasons($show_key);
  my $episodes = $video->episodes($season_key);
  my $all_eps  = $video->all_episodes($show_key);

  # Search
  my $results = $video->search('Breaking Bad', mediatype => 'show');

  # Maintenance
  $video->analyze(12345);

=head1 DESCRIPTION

C<WebService::Plex::Video> provides video-specific browsing for Movies, Shows,
Seasons, and Episodes.  It wraps C</library/sections> and
C</library/metadata> endpoints using Plex media type codes.

Do not instantiate directly.  Access via C<< $plex->video >>.

=head1 MEDIA TYPE CONSTANTS

The following constants are exported for use as C<type> query parameters in
other API calls:

  WebService::Plex::Video::TYPE_MOVIE    # 1
  WebService::Plex::Video::TYPE_SHOW     # 2
  WebService::Plex::Video::TYPE_SEASON   # 3
  WebService::Plex::Video::TYPE_EPISODE  # 4
  WebService::Plex::Video::TYPE_CLIP     # 12

=head1 METHODS

=head2 movies($section_key, %params)

Returns all movies in a library section (C<type=1>).  Optional C<%params>
are forwarded as additional query parameters (e.g. C<sort>, C<unwatched>).

=head2 shows($section_key, %params)

Returns all shows in a library section (C<type=2>).

=head2 seasons($show_key, %params)

Returns the seasons of a show via C</library/metadata/$show_key/children>.

=head2 episodes($season_key, %params)

Returns the episodes of a season via
C</library/metadata/$season_key/children>.

=head2 all_episodes($show_key, %params)

Returns all episodes of a show across all seasons via
C</library/metadata/$show_key/allLeaves>.

=head2 search($query, %params)

Searches for video content via C</hubs/search>.  Pass
C<mediatype =E<gt> 'movie'>, C<'show'>, or C<'episode'> to narrow results.

=head2 analyze($rating_key)

Triggers media analysis (stream detection) via
C<PUT /library/metadata/$key/analyze>.

=head2 optimize($rating_key, %params)

Creates an optimized version of the video
(C<PUT /library/metadata/$key/optimize>).

=head2 search_subtitles($rating_key, %params)

Searches for on-demand subtitles.  Defaults: C<language =E<gt> 'en'>,
C<hearingImpaired =E<gt> 0>, C<forced =E<gt> 0>.

=head2 download_subtitle($rating_key, $subtitle_key)

Downloads a subtitle found via C<search_subtitles>.

=head2 remove_subtitle($subtitle_stream_key)

Removes an uploaded or downloaded subtitle by its stream key.

=head1 DEPENDENCIES

Relies on the L<WebService::Plex> connection object passed at construction.
No additional CPAN modules are required beyond those declared by
L<WebService::Plex>.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex>

=item L<WebService::Plex::Library>

=item L<WebService::Plex::Audio>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

GNU General Public License, version 3 or later.
See L<https://www.gnu.org/licenses/> for details.

=cut
