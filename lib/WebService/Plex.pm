use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex 0.01 {
    use LWP::UserAgent;
    use HTTP::Request;
    use JSON::XS;
    use URI::Escape qw(uri_escape);
    use Carp qw(croak);
    use builtin qw(true false);
    use WebService::Plex::Server;
    use WebService::Plex::Library;

    field $baseurl   :param;
    field $token     :param;
    field $timeout   :param = 30;
    field $_ua;
    field $_json;
    field $_server;
    field $_library;

    ADJUST {
        croak "baseurl required" unless $baseurl;
        croak "token required"   unless $token;
        $_json = JSON::XS->new->utf8;
    }

    my method _ua {
        return $_ua if $_ua;
        my $ua = LWP::UserAgent->new(timeout => $timeout);
        $ua->default_header('Accept'           => 'application/json');
        $ua->default_header('X-Plex-Token'     => $token);
        $ua->default_header('X-Plex-Product'   => 'WebService::Plex');
        $ua->default_header('X-Plex-Version'   => '0.01');
        $ua->default_header('X-Plex-Platform'  => 'Perl');
        $_ua = $ua;
        return $_ua;
    }

    # ----------------------------------------------------------- submodules

    method server  { $_server  //= WebService::Plex::Server->new(plex => $self) }
    method library { $_library //= WebService::Plex::Library->new(plex => $self) }

    # ----------------------------------------------------------- raw HTTP

    my method _decode ($res) {
        croak "HTTP error: " . $res->status_line unless $res->is_success;
        return true unless $res->content;
        my $data = eval { $_json->decode($res->content) };
        croak "JSON parse error: $@" if $@;
        return $data;
    }

    method get ($path, %params) {
        my $url = $baseurl . $path;
        $url .= '?' . join('&', map { uri_escape($_) . '=' . uri_escape($params{$_}) } keys %params) if %params;
        $self->&_decode($self->&_ua->get($url));
    }

    method post ($path, %params) {
        $self->&_decode($self->&_ua->post($baseurl . $path, \%params));
    }

    method put ($path) {
        my $req = HTTP::Request->new(PUT => $baseurl . $path);
        $self->&_decode($self->&_ua->request($req));
    }

    method delete ($path) {
        $self->&_decode($self->&_ua->delete($baseurl . $path));
    }

    # ----------------------------------------------------------- playlists

    method playlists (%params) { $self->get('/playlists', %params) }

    method playlist ($id)       { $self->get("/playlists/$id") }
    method playlist_items ($id) { $self->get("/playlists/$id/items") }

    # ----------------------------------------------------------- collections

    method collections ($section_key) {
        $self->get("/library/sections/$section_key/collections");
    }

    method collection ($rating_key) {
        $self->get("/library/collections/$rating_key");
    }

}

1;
__END__

=head1 NAME

WebService::Plex - Perl client for the Plex Media Server HTTP API

=head1 VERSION

0.01

=head1 SYNOPSIS

  use v5.42;
  use WebService::Plex;

  my $plex = WebService::Plex->new(
      baseurl => 'http://localhost:32400',
      token   => $ENV{PLEX_TOKEN},
  );

  # Server management via submodule accessor
  my $sessions = $plex->server->sessions;
  $plex->server->run_task('CleanOldBundles');

  # Library browsing
  my $sections = $plex->library->sections;
  my $movies   = $plex->library->section_all(1, type => 1);

  # Playback state
  $plex->library->mark_played(12345);
  $plex->library->update_progress(12345, 60_000, 'playing');

=head1 DESCRIPTION

C<WebService::Plex> is a thin Perl wrapper around the Plex Media Server HTTP
API.  Each method issues the appropriate HTTP request and returns the decoded
JSON response as a plain Perl data structure.  Methods croak on HTTP errors or
JSON parse failures.

Requires Perl v5.42 or later.  The distribution uses the native C<class>
object system, named-parameter constructors, and C<builtin::true>/false
throughout.

=head1 CONSTRUCTOR

=head2 new(%args)

  my $plex = WebService::Plex->new(
      baseurl => 'http://192.168.1.10:32400',
      token   => 'xxxxxxxxxxxxxxxxxxxx',
      timeout => 60,
  );

Creates and returns a new client instance.

=over 4

=item baseurl (required)

Base URL of the Plex Media Server, e.g. C<http://localhost:32400>.  No
trailing slash.

=item token (required)

Plex authentication token, passed as the C<X-Plex-Token> header on every
request.

=item timeout (optional, default 30)

HTTP request timeout in seconds.

=back

=head1 SUBMODULES

Logical groups of API methods are accessed through lazy submodule accessors.
Each accessor instantiates its submodule on first call and caches it
thereafter.

=head2 server

Returns a L<WebService::Plex::Server> instance covering identity, preferences,
active sessions, butler tasks, and server diagnostics.

  $plex->server->sessions;
  $plex->server->set_preference('LogVerbose', 1);
  $plex->server->run_task('RefreshPeriodicMetadata');

=head2 library

Returns a L<WebService::Plex::Library> instance covering library sections,
metadata, search, maintenance, and playback state.

  $plex->library->sections;
  $plex->library->section_all(1, type => 1);
  $plex->library->mark_played(12345);

=head1 METHODS

The following methods are available directly on the C<WebService::Plex> object.

=head2 Playlists

=over 4

=item playlists(%params)

Returns all playlists.  Optional C<%params> are forwarded as query parameters.

=item playlist($id)

Returns a single playlist by ID.

=item playlist_items($id)

Returns the items in a playlist.

=back

=head2 Collections

=over 4

=item collections($section_key)

Returns all collections in a library section.

=item collection($rating_key)

Returns a single collection by rating key.

=back

=head1 DEPENDENCIES

=over 4

=item L<Carp>

=item L<HTTP::Request>

=item L<JSON::XS>

=item L<LWP::UserAgent>

=item L<URI::Escape>

=back

Requires Perl v5.42.0 or later for native C<class>, C<field>, and C<method>
support.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex::Server>

=item L<WebService::Plex::Library>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

This software is released under the same terms as Perl 5 itself.
See L<perlartistic> and L<perlgpl> for details.

=cut