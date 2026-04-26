use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";
use PlexIntegration qw(plex_or_skip);

my $plex = plex_or_skip();

# capabilities
my $caps = $plex->server->capabilities;
ok $caps->{MediaContainer}, 'capabilities returns MediaContainer';

# preferences -- returns list of settings
my $prefs = $plex->server->preferences;
ok $prefs, 'preferences returns data';
my $settings = $prefs->{MediaContainer}{Setting} // [];
$settings = [$settings] unless ref $settings eq 'ARRAY';
ok scalar @$settings > 0, 'at least one preference setting';

# sessions -- empty on a fresh test server but must not error
my $sessions = $plex->server->sessions;
ok $sessions, 'sessions returns data';

# butler tasks
my $tasks = $plex->server->scheduled_tasks;
ok $tasks, 'scheduled_tasks returns data';
my $task_list = $tasks->{MediaContainer}{ButlerTask} // [];
$task_list = [$task_list] unless ref $task_list eq 'ARRAY';
ok scalar @$task_list > 0, 'at least one butler task';

# updater status
my $status = $plex->server->update_status;
ok $status, 'update_status returns data';

done_testing;
