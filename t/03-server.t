use v5.42;
use Test::More;
use Test::Exception;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Server;

my $fake   = FakePlex->new;
my $server = WebService::Plex::Server->new(plex => $fake);

# --- server info ---

$server->identity;
is $fake->last_call->{method}, 'get',       'identity uses GET';
is $fake->last_call->{path},   '/identity', 'identity path';

$server->capabilities;
is $fake->last_call->{path}, '/', 'capabilities path';

$server->preferences;
is $fake->last_call->{path}, '/:/prefs', 'preferences path';

$server->activities;
is $fake->last_call->{path}, '/activities', 'activities path';

$server->sessions;
is $fake->last_call->{path}, '/status/sessions', 'sessions path';

$server->transcode_sessions;
is $fake->last_call->{path}, '/transcode/sessions', 'transcode_sessions path';

$server->clients;
is $fake->last_call->{path}, '/clients', 'clients path';

$server->devices;
is $fake->last_call->{path}, '/devices', 'devices path';

# --- set_preference ---

$server->set_preference('myKey', 'myVal');
is   $fake->last_call->{method}, 'put',                   'set_preference uses PUT';
like $fake->last_call->{path},   qr{/:/prefs\?myKey=myVal}, 'set_preference path + param';

$server->set_preference('has space', 'a b');
like $fake->last_call->{path}, qr{has%20space=a%20b}, 'set_preference URI-escapes key and value';

# --- create_token ---

$server->create_token;
is $fake->last_call->{method},         'get',            'create_token uses GET';
is $fake->last_call->{path},           '/security/token','create_token path';
is $fake->last_call->{params}{type},   'delegation',     'create_token default type';
is $fake->last_call->{params}{scope},  'all',            'create_token default scope';

$server->create_token(type => 'managed');
is $fake->last_call->{params}{type},  'managed', 'create_token custom type';
is $fake->last_call->{params}{scope}, 'all',     'create_token scope unchanged';

# --- butler / tasks ---

$server->scheduled_tasks;
is $fake->last_call->{method}, 'get',     'scheduled_tasks uses GET';
is $fake->last_call->{path},   '/butler', 'scheduled_tasks path';

$server->run_task('CleanOldBundles');
is $fake->last_call->{method}, 'post',                   'run_task uses POST';
is $fake->last_call->{path},   '/butler/CleanOldBundles','run_task path';

$server->stop_task('CleanOldBundles');
is $fake->last_call->{method}, 'delete',                 'stop_task uses DELETE';
is $fake->last_call->{path},   '/butler/CleanOldBundles','stop_task path';

# --- diagnostics ---

$server->server_logs;
is $fake->last_call->{path}, '/logs', 'server_logs path';

$server->check_for_updates;
is $fake->last_call->{path}, '/updater/check', 'check_for_updates path';

$server->update_status;
is $fake->last_call->{path}, '/updater/status', 'update_status path';

done_testing;
