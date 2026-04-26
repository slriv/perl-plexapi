use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Client {
    use URI::Escape qw(uri_escape);

    field $plex       :param;
    field $client_url :param;   # e.g. http://192.168.1.50:32433
    field $_cmd_id = 0;

    # commandID must increment with each request for proper client sequencing.
    my method _cmd ($path, %params) {
        $_cmd_id++;
        $plex->get_abs($client_url . $path, commandID => $_cmd_id, %params);
    }

    # ----------------------------------------------------------- playback

    method play  { $self->&_cmd('/player/playback/play') }
    method pause { $self->&_cmd('/player/playback/pause') }
    method stop  { $self->&_cmd('/player/playback/stop') }

    method seek ($offset_ms) {
        $self->&_cmd('/player/playback/seekTo', offset => $offset_ms);
    }

    method skip_next             { $self->&_cmd('/player/playback/skipNext') }
    method skip_prev             { $self->&_cmd('/player/playback/skipPrevious') }
    method skip_to ($key)        { $self->&_cmd('/player/playback/skipTo', key => $key) }
    method step_back             { $self->&_cmd('/player/playback/stepBack') }
    method step_forward          { $self->&_cmd('/player/playback/stepForward') }

    method set_volume ($level) {
        $self->&_cmd('/player/playback/setParameters', volume => $level);
    }

    method set_repeat ($repeat) {
        # 0=off 1=one 2=all
        $self->&_cmd('/player/playback/setParameters', repeat => $repeat);
    }

    method set_shuffle ($shuffle) {
        # 0=off 1=on
        $self->&_cmd('/player/playback/setParameters', shuffle => $shuffle);
    }

    method set_audio_stream ($stream_id) {
        $self->&_cmd('/player/playback/setStreams', audioStreamID => $stream_id);
    }

    method set_subtitle_stream ($stream_id) {
        $self->&_cmd('/player/playback/setStreams', subtitleStreamID => $stream_id);
    }

    method set_video_stream ($stream_id) {
        $self->&_cmd('/player/playback/setStreams', videoStreamID => $stream_id);
    }

    method refresh_play_queue ($play_queue_id) {
        $self->&_cmd('/player/playback/refreshPlayQueue',
            playQueueID => $play_queue_id);
    }

    method timelines { $self->&_cmd('/player/timeline/poll') }

    # ----------------------------------------------------------- navigation

    method nav_up         { $self->&_cmd('/player/navigation/up') }
    method nav_down       { $self->&_cmd('/player/navigation/down') }
    method nav_left       { $self->&_cmd('/player/navigation/left') }
    method nav_right      { $self->&_cmd('/player/navigation/right') }
    method nav_select     { $self->&_cmd('/player/navigation/select') }
    method nav_back       { $self->&_cmd('/player/navigation/back') }
    method nav_home       { $self->&_cmd('/player/navigation/home') }
    method nav_music      { $self->&_cmd('/player/navigation/music') }
    method nav_context_menu { $self->&_cmd('/player/navigation/contextMenu') }
    method nav_toggle_osd { $self->&_cmd('/player/navigation/toggleOSD') }
    method nav_page_up    { $self->&_cmd('/player/navigation/pageUp') }
    method nav_page_down  { $self->&_cmd('/player/navigation/pageDown') }
}

1;
__END__

=head1 NAME

WebService::Plex::Client - Remote playback and navigation control for Plex clients

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $client = WebService::Plex::Client->new(
      plex       => $plex,
      client_url => 'http://192.168.1.50:32433',
  );

  $client->play;
  $client->pause;
  $client->seek(120_000);       # seek to 2 minutes
  $client->set_volume(75);
  $client->set_repeat(2);       # repeat all
  $client->set_shuffle(1);
  $client->set_audio_stream(3);
  $client->skip_to($key);
  $client->step_forward;

  # Navigation
  $client->nav_home;
  $client->nav_music;
  $client->nav_toggle_osd;
  $client->nav_context_menu;

=head1 DESCRIPTION

C<WebService::Plex::Client> provides remote playback and UI navigation
control for a specific Plex client device.

Unlike other submodules, C<WebService::Plex::Client> targets the client
device's own HTTP endpoint (C<client_url>) rather than the Plex Media Server.
Responses from the client are XML; they are returned as raw strings.

Each command automatically increments an internal C<commandID> counter, which
Plex clients use to sequence and deduplicate requests.

=head1 CONSTRUCTOR

=head2 new(%args)

  my $client = WebService::Plex::Client->new(
      plex       => $plex,
      client_url => 'http://192.168.1.50:32433',
  );

=over 4

=item plex (required)

A L<WebService::Plex> connection object, used for its token and HTTP stack.

=item client_url (required)

Base URL of the target Plex client, including port (typically C<32433>).

=back

=head1 METHODS

=head2 Playback

=head3 play

Resumes or starts playback.

=head3 pause

Pauses playback.

=head3 stop

Stops playback.

=head3 seek($offset_ms)

Seeks to C<$offset_ms> milliseconds from the start.

=head3 skip_next

Skips to the next item in the queue.

=head3 skip_prev

Skips to the previous item in the queue.

=head3 skip_to($key)

Skips to a specific item by rating key.

=head3 step_back

Steps back a short interval.

=head3 step_forward

Steps forward a short interval.

=head3 set_volume($level)

Sets the volume to C<$level> (0-100).

=head3 set_repeat($mode)

Sets repeat mode: C<0> = off, C<1> = repeat one, C<2> = repeat all.

=head3 set_shuffle($mode)

Sets shuffle: C<0> = off, C<1> = on.

=head3 set_audio_stream($stream_id)

Selects an audio stream by ID.

=head3 set_subtitle_stream($stream_id)

Selects a subtitle stream by ID.

=head3 set_video_stream($stream_id)

Selects a video stream by ID.

=head3 refresh_play_queue($play_queue_id)

Refreshes the play queue on the client.

=head3 timelines

Returns current playback timeline state from the client.

=head2 Navigation

=head3 nav_up, nav_down, nav_left, nav_right

Directional navigation.

=head3 nav_select

Confirms the current selection.

=head3 nav_back

Returns to the previous screen.

=head3 nav_home

Returns to the home screen.

=head3 nav_music

Navigates to the music section.

=head3 nav_context_menu

Opens the context menu.

=head3 nav_toggle_osd

Toggles the on-screen display.

=head3 nav_page_up, nav_page_down

Scrolls up or down by one page.

=head1 DEPENDENCIES

Relies on the L<WebService::Plex> connection object passed at construction.
No additional CPAN modules are required beyond those declared by
L<WebService::Plex>.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex>

=item L<WebService::Plex::Server>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

GNU General Public License, version 3 or later.
See L<https://www.gnu.org/licenses/> for details.

=cut
