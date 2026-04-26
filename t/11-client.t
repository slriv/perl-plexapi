use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Client;

my $fake   = FakePlex->new;
my $client = WebService::Plex::Client->new(
    plex       => $fake,
    client_url => 'http://player.local:32433',
);

# --- playback ---

$client->play;
is $fake->last_call->{method}, 'get_abs',                                     'play uses get_abs';
like $fake->last_call->{path}, qr{^http://player\.local:32433},               'play uses client_url';
like $fake->last_call->{path}, qr{/player/playback/play},                     'play path';
ok $fake->last_call->{params}{commandID},                                      'play includes commandID';

$client->pause;
like $fake->last_call->{path}, qr{/player/playback/pause}, 'pause path';

$client->stop;
like $fake->last_call->{path}, qr{/player/playback/stop}, 'stop path';

$client->seek(120_000);
like $fake->last_call->{path},          qr{/player/playback/seekTo}, 'seek path';
is $fake->last_call->{params}{offset},  120_000,                     'seek offset param';

$client->skip_next;
like $fake->last_call->{path}, qr{/player/playback/skipNext}, 'skip_next path';

$client->skip_prev;
like $fake->last_call->{path}, qr{/player/playback/skipPrevious}, 'skip_prev path';

$client->set_volume(75);
like $fake->last_call->{path},          qr{/player/playback/setParameters}, 'set_volume path';
is $fake->last_call->{params}{volume},  75,                                  'set_volume param';

# --- commandID increments ---

my $id1 = $client->play;
my $id2 = $client->play;
# FakePlex captures params; commandID should be different each call
my $cmd1 = do { $client->play; $fake->last_call->{params}{commandID} };
my $cmd2 = do { $client->play; $fake->last_call->{params}{commandID} };
ok $cmd2 > $cmd1, 'commandID increments with each call';

# --- navigation ---

$client->nav_up;
like $fake->last_call->{path}, qr{/player/navigation/up},     'nav_up path';

$client->nav_down;
like $fake->last_call->{path}, qr{/player/navigation/down},   'nav_down path';

$client->nav_left;
like $fake->last_call->{path}, qr{/player/navigation/left},   'nav_left path';

$client->nav_right;
like $fake->last_call->{path}, qr{/player/navigation/right},  'nav_right path';

$client->nav_select;
like $fake->last_call->{path}, qr{/player/navigation/select}, 'nav_select path';

$client->nav_back;
like $fake->last_call->{path}, qr{/player/navigation/back},   'nav_back path';

$client->nav_home;
like $fake->last_call->{path}, qr{/player/navigation/home},   'nav_home path';

# --- extended playback ---

$client->skip_to('key123');
like $fake->last_call->{path},        qr{/player/playback/skipTo}, 'skip_to path';
is $fake->last_call->{params}{key},   'key123',                    'skip_to key param';

$client->step_back;
like $fake->last_call->{path}, qr{/player/playback/stepBack},    'step_back path';

$client->step_forward;
like $fake->last_call->{path}, qr{/player/playback/stepForward}, 'step_forward path';

$client->set_repeat(2);
like $fake->last_call->{path},           qr{/player/playback/setParameters}, 'set_repeat path';
is $fake->last_call->{params}{repeat},   2,                                   'set_repeat param';

$client->set_shuffle(1);
is $fake->last_call->{params}{shuffle},  1, 'set_shuffle param';

$client->set_audio_stream(3);
like $fake->last_call->{path},                   qr{/player/playback/setStreams}, 'set_audio_stream path';
is $fake->last_call->{params}{audioStreamID},    3,                               'set_audio_stream param';

$client->set_subtitle_stream(5);
is $fake->last_call->{params}{subtitleStreamID}, 5, 'set_subtitle_stream param';

$client->set_video_stream(1);
is $fake->last_call->{params}{videoStreamID},    1, 'set_video_stream param';

$client->refresh_play_queue(999);
like $fake->last_call->{path},               qr{refreshPlayQueue},  'refresh_play_queue path';
is $fake->last_call->{params}{playQueueID},  999,                   'refresh_play_queue param';

$client->timelines;
like $fake->last_call->{path}, qr{/player/timeline/poll}, 'timelines path';

# --- extended navigation ---

$client->nav_music;
like $fake->last_call->{path}, qr{/player/navigation/music},       'nav_music path';

$client->nav_context_menu;
like $fake->last_call->{path}, qr{/player/navigation/contextMenu}, 'nav_context_menu path';

$client->nav_toggle_osd;
like $fake->last_call->{path}, qr{/player/navigation/toggleOSD},   'nav_toggle_osd path';

$client->nav_page_up;
like $fake->last_call->{path}, qr{/player/navigation/pageUp},      'nav_page_up path';

$client->nav_page_down;
like $fake->last_call->{path}, qr{/player/navigation/pageDown},    'nav_page_down path';

done_testing;
