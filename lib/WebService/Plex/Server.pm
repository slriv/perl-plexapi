use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Server {
    use URI::Escape qw(uri_escape);

    field $plex :param;

    # ----------------------------------------------------------- server info

    method identity           { $plex->get('/identity') }
    method capabilities       { $plex->get('/') }
    method preferences        { $plex->get('/:/prefs') }
    method activities         { $plex->get('/activities') }
    method sessions           { $plex->get('/status/sessions') }
    method transcode_sessions { $plex->get('/transcode/sessions') }
    method background_tasks   { $plex->get('/status/sessions/background') }
    method clients            { $plex->get('/clients') }
    method devices            { $plex->get('/devices') }
    method agents (%args)     { $plex->get('/system/agents', %args) }

    method set_preference ($key, $value) {
        $plex->put('/:/prefs', $key => $value);
    }

    method create_token (%args) {
        $args{type}  //= 'delegation';
        $args{scope} //= 'all';
        $plex->get('/security/token', %args);
    }

    # ----------------------------------------------------------- hubs

    method hubs (%args)             { $plex->get('/hubs', %args) }
    method continue_watching        { $plex->get('/hubs/continueWatching/items') }
    method promoted_hubs (%args)    { $plex->get('/hubs/promoted', %args) }
    method hub_search ($query, %args) {
        $plex->get('/hubs/search', query => $query, %args);
    }

    # ----------------------------------------------------------- history

    method history (%args) {
        $args{sort} //= 'viewedAt:desc';
        $plex->get('/status/sessions/history/all', %args);
    }

    method delete_history ($history_id) {
        $plex->delete("/status/sessions/history/$history_id");
    }

    # ----------------------------------------------------------- butler / tasks

    method scheduled_tasks { $plex->get('/butler') }

    method run_task ($task)  { $plex->post("/butler/$task") }
    method stop_task ($task) { $plex->delete("/butler/$task") }

    # ----------------------------------------------------------- updater

    method server_logs       { $plex->get('/logs') }
    method check_for_updates { $plex->get('/updater/check') }
    method update_status     { $plex->get('/updater/status') }
    method apply_updates     { $plex->put('/updater/apply') }
}

1;
__END__

=head1 NAME

WebService::Plex::Server - Server identity, preferences, tasks, and diagnostics

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $server = $plex->server;

  my $id      = $server->identity;
  my $sess    = $server->sessions;
  my $history = $server->history(accountID => 1);
  my $hubs    = $server->hubs;

  $server->set_preference('LogVerbose', 1);
  $server->run_task('CleanOldBundles');
  $server->apply_updates;

=head1 DESCRIPTION

C<WebService::Plex::Server> provides access to server identity, runtime
preferences, session inspection, hubs, playback history, butler task
management, and software update control.

Obtain an instance through the C<server> accessor on a L<WebService::Plex>
object -- do not instantiate directly.

=head1 METHODS

=head2 Server Information

=head3 identity

Returns server identity information (C<GET /identity>).

=head3 capabilities

Returns the server capabilities document (C<GET />).

=head3 preferences

Returns all current server preferences (C<GET /:/prefs>).

=head3 activities

Returns currently running server-side activities (C<GET /activities>).

=head3 sessions

Returns all active client sessions (C<GET /status/sessions>).

=head3 transcode_sessions

Returns all active transcode sessions (C<GET /transcode/sessions>).

=head3 background_tasks

Returns active background tasks (C<GET /status/sessions/background>).

=head3 clients

Returns currently connected client devices (C<GET /clients>).

=head3 devices

Returns all known devices associated with this server (C<GET /devices>).

=head3 agents(%args)

Returns available metadata agents (C<GET /system/agents>).  Pass
C<< mediaType => $type >> to filter by media type code.

=head2 Configuration

=head3 set_preference($key, $value)

Sets a single server preference via C<PUT /:/prefs>.

  $server->set_preference('LogVerbose', 1);

=head3 create_token(%args)

Requests a scoped token (C<GET /security/token>).  Defaults to
C<type =E<gt> 'delegation', scope =E<gt> 'all'>.

=head2 Hubs

=head3 hubs(%args)

Returns all home screen hubs (C<GET /hubs>).

=head3 continue_watching

Returns items from the Continue Watching hub
(C<GET /hubs/continueWatching/items>).

=head3 promoted_hubs(%args)

Returns promoted hubs (C<GET /hubs/promoted>).

=head3 hub_search($query, %args)

Searches across hubs (C<GET /hubs/search>).

  my $results = $server->hub_search('Breaking Bad');

=head2 History

=head3 history(%args)

Returns watched history (C<GET /status/sessions/history/all>).
Defaults to C<sort =E<gt> 'viewedAt:desc'>.  Accepts optional
C<accountID>, C<metadataItemID>, and C<librarySectionID> filters.

=head3 delete_history($history_id)

Deletes a single history entry (C<DELETE /status/sessions/history/$id>).

=head2 Butler Tasks

=head3 scheduled_tasks

Returns the list of butler tasks and schedules (C<GET /butler>).

=head3 run_task($task_name)

Starts a butler task immediately (C<POST /butler/$task>).

  $server->run_task('CleanOldBundles');

=head3 stop_task($task_name)

Stops a running butler task (C<DELETE /butler/$task>).

=head2 Updater

=head3 server_logs

Returns server log data (C<GET /logs>).

=head3 check_for_updates

Triggers an update availability check (C<GET /updater/check>).

=head3 update_status

Returns the current software update status (C<GET /updater/status>).

=head3 apply_updates

Applies a downloaded update (C<PUT /updater/apply>).

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

GNU General Public License, version 3 or later.
See L<https://www.gnu.org/licenses/> for details.

=cut
