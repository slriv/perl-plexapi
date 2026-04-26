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
    use WebService::Plex::Playlist;
    use WebService::Plex::Collection;
    use WebService::Plex::Video;
    use WebService::Plex::Audio;
    use WebService::Plex::MyPlex;
    use WebService::Plex::Client;
    use WebService::Plex::DownloadQueue;
    use WebService::Plex::PlayQueue;
    use WebService::Plex::Photo;
    use WebService::Plex::Services;
    use WebService::Plex::LiveTV;

    field $baseurl   :param;
    field $token     :param = '';
    field $timeout   :param = 30;
    field $_ua;
    field $_json;
    field $_server;
    field $_library;
    field $_playlist;
    field $_collection;
    field $_video;
    field $_audio;
    field $_myplex;
    field $_alert;
    field $_download_queue;
    field $_play_queue;
    field $_photo;
    field $_services;
    field $_livetv;

    ADJUST {
        croak "baseurl required" unless $baseurl;
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

    # ----------------------------------------------------------- connection info

    method baseurl { $baseurl }
    method token   { $token }

    # ----------------------------------------------------------- submodules

    method server   { $_server   //= WebService::Plex::Server->new(plex => $self) }
    method library  { $_library  //= WebService::Plex::Library->new(plex => $self) }
    method playlist   { $_playlist   //= WebService::Plex::Playlist->new(plex => $self) }
    method collection { $_collection //= WebService::Plex::Collection->new(plex => $self) }
    method video      { $_video      //= WebService::Plex::Video->new(plex => $self) }
    method audio      { $_audio      //= WebService::Plex::Audio->new(plex => $self) }
    method myplex     { $_myplex     //= WebService::Plex::MyPlex->new(plex => $self) }

    method client ($client_url) {
        WebService::Plex::Client->new(plex => $self, client_url => $client_url);
    }

    method alert {
        # Loaded lazily -- AnyEvent::WebSocket::Client is a recommends dep.
        require WebService::Plex::Alert;
        $_alert //= WebService::Plex::Alert->new(plex => $self);
    }

    method download_queue {
        $_download_queue //= WebService::Plex::DownloadQueue->new(plex => $self);
    }

    method play_queue {
        $_play_queue //= WebService::Plex::PlayQueue->new(plex => $self);
    }

    method photo {
        $_photo //= WebService::Plex::Photo->new(plex => $self);
    }

    method services {
        $_services //= WebService::Plex::Services->new(plex => $self);
    }

    method livetv {
        $_livetv //= WebService::Plex::LiveTV->new(plex => $self);
    }

    # ----------------------------------------------------------- raw HTTP

    my method _decode ($res) {
        croak "HTTP error: " . $res->status_line unless $res->is_success;
        return true unless $res->content;
        my $data = eval { $_json->decode($res->content) };
        if ($@) {
            my $err = $@;
            # Non-JSON XML response (e.g. client control returns XML) -- return raw.
            # TODO: structured XML parsing for client responses if richer data is needed
            return $res->decoded_content if $res->content =~ m{^\s*<};
            croak "JSON parse error: $err";
        }
        return $data;
    }

    my method _encode_params (%params) {
        return join('&', map { uri_escape($_) . '=' . uri_escape($params{$_}) } keys %params);
    }

    method get ($path, %params) {
        my $url = $baseurl . $path;
        $url .= '?' . $self->&_encode_params(%params) if %params;
        $self->&_decode($self->&_ua->get($url));
    }

    method post ($path, %params) {
        # Plex universally expects query-string params even on POST requests.
        my $url = $baseurl . $path;
        $url .= '?' . $self->&_encode_params(%params) if %params;
        $self->&_decode($self->&_ua->post($url));
    }

    method put ($path, %params) {
        my $url = $baseurl . $path;
        $url .= '?' . $self->&_encode_params(%params) if %params;
        my $req = HTTP::Request->new(PUT => $url);
        $self->&_decode($self->&_ua->request($req));
    }

    method delete ($path, %params) {
        my $url = $baseurl . $path;
        $url .= '?' . $self->&_encode_params(%params) if %params;
        $self->&_decode($self->&_ua->delete($url));
    }

    # Absolute-URL variants used by submodules that target services
    # other than the local Plex server (e.g. plex.tv, discover.provider.plex.tv).

    method get_abs ($url, %params) {
        $url .= '?' . $self->&_encode_params(%params) if %params;
        $self->&_decode($self->&_ua->get($url));
    }

    method post_abs ($url, %params) {
        $url .= '?' . $self->&_encode_params(%params) if %params;
        $self->&_decode($self->&_ua->post($url));
    }

    method put_abs ($url, %params) {
        $url .= '?' . $self->&_encode_params(%params) if %params;
        my $req = HTTP::Request->new(PUT => $url);
        $self->&_decode($self->&_ua->request($req));
    }

    method delete_abs ($url, %params) {
        $url .= '?' . $self->&_encode_params(%params) if %params;
        $self->&_decode($self->&_ua->delete($url));
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

=item token (optional, default '')

Plex authentication token, passed as the C<X-Plex-Token> header on every
request.  May be omitted or left empty when connecting to an unclaimed local
server (e.g. a Docker test instance that has not been linked to a plex.tv
account).

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

=head2 playlist

Returns a L<WebService::Plex::Playlist> instance for listing, fetching,
creating, updating, and managing playlist items.

  $plex->playlist->all;
  $plex->playlist->items(12345);
  $plex->playlist->delete(12345);

=head2 collection

Returns a L<WebService::Plex::Collection> instance for listing, fetching,
creating, updating, and managing collection items.

  $plex->collection->all(1);
  $plex->collection->items(12345);
  $plex->collection->delete(12345);

=head2 video

Returns a L<WebService::Plex::Video> instance for browsing Movies, Shows,
Seasons, and Episodes.

  $plex->video->movies(1);
  $plex->video->seasons($show_key);
  $plex->video->search('Breaking Bad', mediatype => 'show');

=head2 audio

Returns a L<WebService::Plex::Audio> instance for browsing Artists, Albums,
and Tracks.

  $plex->audio->artists(3);
  $plex->audio->tracks($album_key);
  $plex->audio->search('Radiohead', mediatype => 'artist');

=head2 myplex

Returns a L<WebService::Plex::MyPlex> instance for plex.tv account info,
home users, and watchlist management.

  $plex->myplex->account;
  $plex->myplex->watchlist;
  $plex->myplex->add_to_watchlist(12345);

=head2 alert

Returns a L<WebService::Plex::Alert> instance for listening to real-time
server notifications via WebSocket.  Requires L<AnyEvent> and
L<AnyEvent::WebSocket::Client> to be installed.

  $plex->alert->listen(sub {
      my ($notification) = @_;
      say $notification->{type};
      return 1;
  });

=head2 client($client_url)

Returns a new L<WebService::Plex::Client> instance targeting the Plex client
at C<$client_url> (e.g. C<http://192.168.1.50:32433>).  A new instance is
returned on every call since each client device has a distinct URL.

  my $c = $plex->client('http://192.168.1.50:32433');
  $c->play;
  $c->set_volume(80);

=head2 download_queue

Returns a L<WebService::Plex::DownloadQueue> instance for creating and
managing Plex download queues and queue items.

  $plex->download_queue->create(name => 'My Downloads');
  $plex->download_queue->items($queue_id);

=head2 play_queue

Returns a L<WebService::Plex::PlayQueue> instance for managing play queue
state and queue item operations.

  $plex->play_queue->items($queue_id);
  $plex->play_queue->shuffle($queue_id);

=head2 photo

Returns a L<WebService::Plex::Photo> instance for photo transcoding and image
helper requests.

  $plex->photo->transcode(url => $image_url, maxWidth => 400);

=head2 services

Returns a L<WebService::Plex::Services> instance for Plex service endpoints
such as ultrablur.

  $plex->services->ultrablur_colors(format => 'json');

=head2 livetv

Returns a L<WebService::Plex::LiveTV> instance for Live TV DVR, EPG, and
session access.

  $plex->livetv->dvrs(limit => 10);
  $plex->livetv->sessions(state => 'active');

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

=item L<WebService::Plex::Playlist>

=item L<WebService::Plex::Collection>

=item L<WebService::Plex::Video>

=item L<WebService::Plex::Audio>

=item L<WebService::Plex::MyPlex>

=item L<WebService::Plex::Client>

=item L<WebService::Plex::DownloadQueue>

=item L<WebService::Plex::PlayQueue>

=item L<WebService::Plex::Photo>

=item L<WebService::Plex::Services>

=item L<WebService::Plex::LiveTV>

=item L<WebService::Plex::Alert>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

This software is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.  See L<https://www.gnu.org/licenses/> for details.

=cut