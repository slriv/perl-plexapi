use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Server {
    use URI::Escape qw(uri_escape);

    field $plex :param;

    # ----------------------------------------------------------- server info

    method identity             { $plex->get('/identity') }
    method capabilities         { $plex->get('/') }
    method preferences          { $plex->get('/:/prefs') }
    method activities           { $plex->get('/activities') }
    method sessions             { $plex->get('/status/sessions') }
    method transcode_sessions   { $plex->get('/transcode/sessions') }
    method clients              { $plex->get('/clients') }
    method devices              { $plex->get('/devices') }

    method set_preference ($key, $value) {
        # TODO: consider adding %params support to WebService::Plex::put so this
        #       doesn't need to manually build the query string
        $plex->put('/:/prefs?' . uri_escape($key) . '=' . uri_escape($value));
    }

    method create_token (%args) {
        $args{type}  //= 'delegation';
        $args{scope} //= 'all';
        $plex->get('/security/token', %args);
    }

    # ----------------------------------------------------------- butler / tasks

    method scheduled_tasks { $plex->get('/butler') }

    # TODO: verify HTTP verb for run_task against a live server -- POST vs PUT
    method run_task ($task)  { $plex->post("/butler/$task") }
    method stop_task ($task) { $plex->delete("/butler/$task") }

    # ----------------------------------------------------------- diagnostics

    method server_logs        { $plex->get('/logs') }
    method check_for_updates  { $plex->get('/updater/check') }
    method update_status      { $plex->get('/updater/status') }
}

1;
__END__

=head1 NAME

WebService::Plex::Server - Server identity, preferences, tasks, and diagnostics

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $server = $plex->server;

  # Server information
  my $id   = $server->identity;
  my $sess = $server->sessions;

  # Configuration
  $server->set_preference('LogVerbose', 1);

  # Butler maintenance tasks
  my $tasks = $server->scheduled_tasks;
  $server->run_task('CleanOldBundles');

  # Diagnostics
  $server->check_for_updates;

=head1 DESCRIPTION

C<WebService::Plex::Server> provides access to server identity, runtime
preferences, active session inspection, butler maintenance task management,
and server diagnostics.

Do not instantiate this class directly.  Obtain an instance through the
C<server> accessor on a L<WebService::Plex> object:

  my $server = $plex->server;

The accessor is lazily instantiated on first call and cached for the lifetime
of the parent connection.

=head1 METHODS

=head2 Server Information

=head3 identity

Returns server identity information (C</identity>).

=head3 capabilities

Returns the server capabilities document (C</>).

=head3 preferences

Returns all current server preferences (C</:/prefs>).

=head3 activities

Returns currently running server-side activities (C</activities>).

=head3 sessions

Returns all active client sessions (C</status/sessions>).

=head3 transcode_sessions

Returns all active transcode sessions (C</transcode/sessions>).

=head3 clients

Returns currently connected client devices (C</clients>).

=head3 devices

Returns all known devices associated with this server (C</devices>).

=head2 Configuration

=head3 set_preference($key, $value)

Sets a single server preference via C<PUT /:/prefs>.

  $server->set_preference('LogVerbose', 1);
  $server->set_preference('FriendlyName', 'My Plex');

=head3 create_token(%args)

Requests a scoped token from C</security/token>.

=over 4

=item type

Token type.  Defaults to C<'delegation'>.

=item scope

Token scope.  Defaults to C<'all'>.

=back

Returns the token response as a hash reference.

=head2 Butler Tasks

Butler tasks are scheduled server maintenance operations such as database
vacuuming, artwork scanning, and media analysis.  Task names are
case-sensitive strings as returned by L</scheduled_tasks>.

=head3 scheduled_tasks

Returns the list of configured butler tasks and their schedules
(C</butler>).

=head3 run_task($task_name)

Starts the named butler task immediately.

  $server->run_task('CleanOldBundles');
  $server->run_task('RefreshPeriodicMetadata');

=head3 stop_task($task_name)

Stops the named butler task if it is currently running.

=head2 Diagnostics

=head3 server_logs

Returns server log data (C</logs>).

=head3 check_for_updates

Triggers an update availability check (C</updater/check>).

=head3 update_status

Returns the current software update status (C</updater/status>).

=head1 DEPENDENCIES

Relies on the L<WebService::Plex> connection object passed at construction.
No additional CPAN modules are required beyond those declared by
L<WebService::Plex>.

=head1 SEE ALSO

=over 4

=item L<WebService::Plex>

=item L<https://support.plex.tv/articles/butler-tasks/>

=back

=head1 AUTHOR

Sam Robertson

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Sam Robertson.

This software is released under the same terms as Perl 5 itself.
See L<perlartistic> and L<perlgpl> for details.

=cut
