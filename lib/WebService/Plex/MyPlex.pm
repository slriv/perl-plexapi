use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::MyPlex {
    use URI::Escape qw(uri_escape);

    field $plex :param;

    use constant {
        BASE      => 'https://plex.tv',
        WATCHLIST => 'https://discover.provider.plex.tv',
    };

    # ----------------------------------------------------------- account

    method account { $plex->get_abs(BASE . '/api/v2/user') }

    method ping { $plex->get_abs(BASE . '/api/v2/ping') }

    method claim_token { $plex->get_abs(BASE . '/api/claim/token.json') }

    method webhooks { $plex->get_abs(BASE . '/api/v2/user/webhooks') }

    # ----------------------------------------------------------- home users

    method home_users { $plex->get_abs(BASE . '/api/home/users') }

    method switch_home_user ($user_id) {
        $plex->post_abs(BASE . "/api/home/users/$user_id/switch");
    }

    # ----------------------------------------------------------- watchlist
    # TODO: verify filter values against live plex.tv -- 'all', 'unwatched',
    #       'watched' observed in python-plexapi; others may exist

    method watchlist ($filter = 'all', %params) {
        $plex->get_abs(WATCHLIST . "/library/sections/watchlist/$filter", %params);
    }

    method add_to_watchlist ($rating_key) {
        $plex->put_abs(WATCHLIST . '/actions/addToWatchlist?ratingKey=' . uri_escape($rating_key));
    }

    method remove_from_watchlist ($rating_key) {
        $plex->put_abs(WATCHLIST . '/actions/removeFromWatchlist?ratingKey=' . uri_escape($rating_key));
    }

    # ----------------------------------------------------------- users / friends

    method users { $plex->get_abs(BASE . '/api/users/') }

    # ----------------------------------------------------------- devices / resources

    method devices   { $plex->get_abs('https://plex.tv/devices.xml') }
    method resources { $plex->get_abs('https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=1') }

    # ----------------------------------------------------------- webhooks management

    method add_webhook ($url) {
        $plex->post_abs(BASE . '/api/v2/user/webhooks', url => $url);
    }

    method delete_webhook ($url) {
        $plex->delete_abs(BASE . '/api/v2/user/webhooks', url => $url);
    }

    method set_webhooks (@urls) {
        $plex->post_abs(BASE . '/api/v2/user/webhooks',
            (@urls ? ('urls[]' => \@urls) : (urls => '')));
    }

    # ----------------------------------------------------------- geo / network

    method public_ip { $plex->get_abs(BASE . '/:/ip') }

    method geoip ($ip_address) {
        $plex->get_abs(BASE . '/api/v2/geoip', ip_address => $ip_address);
    }

    # ----------------------------------------------------------- sharing
    # Server sharing requires machineIdentifier + section IDs from
    # server discovery.  Not yet implemented.
}

1;
__END__

=head1 NAME

WebService::Plex::MyPlex - plex.tv account, home users, and watchlist

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $my = $plex->myplex;

  # Account
  my $acct  = $my->account;
  my $token = $my->claim_token;

  # Home users
  my $users = $my->home_users;
  $my->switch_home_user($user_id);

  # Watchlist
  my $wl = $my->watchlist;
  $my->add_to_watchlist(12345);
  $my->remove_from_watchlist(12345);

=head1 DESCRIPTION

C<WebService::Plex::MyPlex> provides access to the C<plex.tv> cloud API for
account information, home user management, and watchlist operations.

All methods use absolute URLs targeting C<https://plex.tv> or
C<https://discover.provider.plex.tv> rather than the local Plex Media Server.
Authentication uses the same C<X-Plex-Token> that was provided to the parent
L<WebService::Plex> connection.

Do not instantiate directly.  Access via C<< $plex->myplex >>.

=head1 METHODS

=head2 Account

=head3 account

Returns the authenticated account profile from C</api/v2/user>.

=head3 ping

Refreshes the authentication token via C</api/v2/ping>.

=head3 claim_token

Returns a one-time server claim token from C</api/claim/token.json>.

=head3 webhooks

Returns configured webhooks from C</api/v2/user/webhooks>.

=head2 Home Users

=head3 home_users

Returns the list of home users (C</api/home/users>).

=head3 switch_home_user($user_id)

Switches the active session to the specified home user
(C<POST /api/home/users/$id/switch>).

=head2 Watchlist

=head3 watchlist($filter, %params)

Returns watchlist items from C<discover.provider.plex.tv>.  C<$filter>
defaults to C<'all'>; other values are C<'unwatched'> and C<'watched'>.

=head3 add_to_watchlist($rating_key)

Adds an item to the watchlist by rating key.

=head3 remove_from_watchlist($rating_key)

Removes an item from the watchlist by rating key.

=head2 Users and Friends

=head3 users

Returns all users associated with the account (C<GET /api/users/>).

=head2 Devices and Resources

=head3 devices

Returns all devices linked to the account
(C<GET https://plex.tv/devices.xml>).

=head3 resources

Returns all resources (servers, clients) accessible to the account
(C<GET /api/v2/resources>).

=head2 Webhook Management

=head3 add_webhook($url)

Adds a webhook URL (C<POST /api/v2/user/webhooks>).

=head3 delete_webhook($url)

Removes a webhook URL.

=head3 set_webhooks(@urls)

Replaces all webhooks with the provided list.

=head2 Geo / Network

=head3 public_ip

Returns the public IP address of the client (C<GET /:/ip>).

=head3 geoip($ip_address)

Returns geolocation data for an IP address
(C<GET /api/v2/geoip>).

=head2 Server Sharing

Server sharing requires the server C<machineIdentifier> and section IDs
from server discovery.  Not yet implemented.

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
