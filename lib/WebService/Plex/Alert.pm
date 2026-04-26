use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Alert {
    use JSON::XS;
    use Carp qw(croak);

    field $plex  :param;
    field $_json;

    ADJUST { $_json = JSON::XS->new->utf8 }

    use constant NOTIFICATIONS_PATH => '/:/websockets/notifications';

    my method _ws_url {
        my $base  = $plex->baseurl;
        my $token = $plex->token;
        (my $ws_base = $base) =~ s{^http}{ws};
        return $ws_base . NOTIFICATIONS_PATH . '?X-Plex-Token=' . $token;
    }

    # ----------------------------------------------------------- listener

    method listen ($callback) {
        # AnyEvent::WebSocket::Client is a recommends dependency.
        # Install it (and AnyEvent) to use this method.
        require AnyEvent;
        require AnyEvent::WebSocket::Client;

        my $client = AnyEvent::WebSocket::Client->new;
        my $cv     = AnyEvent->condvar;

        $client->connect($self->&_ws_url)->cb(sub {
            my $conn = eval { shift->recv };
            if ($@) {
                $cv->croak($@);
                return;
            }

            $conn->on(each_message => sub {
                my ($conn, $msg) = @_;
                my $data = eval { $_json->decode($msg->decoded_body) };
                # TODO: surface parse errors -- silently ignoring for now
                return if $@;

                my $nc   = $data->{NotificationContainer} // {};
                my $keep = $callback->($nc);
                $conn->close unless ($keep // 1);
            });

            $conn->on(finish => sub { $cv->send });
        });

        $cv->recv;
    }

    # ----------------------------------------------------------- url helper (testable)

    method ws_url { $self->&_ws_url }
}

1;
__END__

=head1 NAME

WebService::Plex::Alert - WebSocket notification listener for Plex Media Server events

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $alerts = $plex->alert;

  $alerts->listen(sub {
      my ($notification) = @_;  # decoded NotificationContainer hashref
      my $type = $notification->{type};
      say "Got alert: $type";
      return 1;  # return false to stop listening
  });

=head1 DESCRIPTION

C<WebService::Plex::Alert> opens a persistent WebSocket connection to the
Plex Media Server notification endpoint and dispatches incoming events to a
user-supplied callback.

=head2 Optional Dependency

This module requires L<AnyEvent> and L<AnyEvent::WebSocket::Client>, which
are not installed by default.  Install them before using C<listen>:

  cpanm AnyEvent AnyEvent::WebSocket::Client

=head1 METHODS

=head2 listen($callback)

Connects to C</:/websockets/notifications> and blocks until the connection
closes or the callback returns a false value.

  $alerts->listen(sub {
      my ($nc) = @_;     # NotificationContainer hashref
      my $type = $nc->{type};

      # return false to disconnect
      return $type ne 'stopping';
  });

The C<$nc> argument is the decoded C<NotificationContainer> hash from the
server message.  Common C<type> values:

=over 4

=item timeline

Library item state changes.  Contains C<TimelineEntry> array with C<state>
(0=created, 1=processing, 5=processed, 9=deleted) and media C<type>.

=item playing

Active playback state updates.  Contains C<PlaySessionStateNotification>.

=item activity

Background task progress.

=item reachability

Server reachability changes.

=back

=head2 ws_url

Returns the computed WebSocket URL for the current connection.  Useful for
debugging.

=head1 DEPENDENCIES

Runtime: L<JSON::XS> (via L<WebService::Plex>).

Optional (required for C<listen>): L<AnyEvent>, L<AnyEvent::WebSocket::Client>.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex>

=item L<AnyEvent::WebSocket::Client>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

This software is released under the same terms as Perl 5 itself.
See L<perlartistic> and L<perlgpl> for details.

=cut
