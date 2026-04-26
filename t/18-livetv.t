use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::LiveTV;

my $fake   = FakePlex->new;
my $livetv = WebService::Plex::LiveTV->new(plex => $fake);

$livetv->dvrs(limit => 10);
is $fake->last_call->{method}, 'get', 'dvrs uses GET';
is $fake->last_call->{path}, '/livetv/dvrs?limit=10', 'dvrs path';

$livetv->create_dvr(name => 'Test DVR');
is $fake->last_call->{method}, 'post', 'create_dvr uses POST';
is $fake->last_call->{path}, '/livetv/dvrs', 'create_dvr path';

$livetv->dvr('abc123');
is $fake->last_call->{path}, '/livetv/dvrs/abc123', 'dvr path';

$livetv->delete_dvr('abc123');
is $fake->last_call->{method}, 'delete', 'delete_dvr uses DELETE';
is $fake->last_call->{path}, '/livetv/dvrs/abc123', 'delete_dvr path';

$livetv->tune_channel('abc123', '101', quality => '720p');
is $fake->last_call->{method}, 'post', 'tune_channel uses POST';
is $fake->last_call->{path}, '/livetv/dvrs/abc123/channels/101/tune', 'tune_channel path';

$livetv->dvr_device('abc123', 'dev456');
is $fake->last_call->{path}, '/livetv/dvrs/abc123/devices/dev456', 'dvr_device path';

$livetv->update_dvr_device('abc123', 'dev456', enabled => 1);
is $fake->last_call->{method}, 'put', 'update_dvr_device uses PUT';
is $fake->last_call->{path}, '/livetv/dvrs/abc123/devices/dev456?enabled=1', 'update_dvr_device path';

$livetv->delete_dvr_device('abc123', 'dev456');
is $fake->last_call->{method}, 'delete', 'delete_dvr_device uses DELETE';
is $fake->last_call->{path}, '/livetv/dvrs/abc123/devices/dev456', 'delete_dvr_device path';

$livetv->dvr_lineups('abc123', refresh => 1);
is $fake->last_call->{method}, 'put', 'dvr_lineups uses PUT';
is $fake->last_call->{path}, '/livetv/dvrs/abc123/lineups?refresh=1', 'dvr_lineups path';

$livetv->delete_dvr_lineups('abc123');
is $fake->last_call->{method}, 'delete', 'delete_dvr_lineups uses DELETE';
is $fake->last_call->{path}, '/livetv/dvrs/abc123/lineups', 'delete_dvr_lineups path';

$livetv->dvr_prefs('abc123', page => 2);
is $fake->last_call->{method}, 'put', 'dvr_prefs uses PUT';
is $fake->last_call->{path}, '/livetv/dvrs/abc123/prefs?page=2', 'dvr_prefs path';

$livetv->reload_guide('abc123');
is $fake->last_call->{path}, '/livetv/dvrs/abc123/reloadGuide', 'reload_guide path';

$livetv->remove_reload_guide('abc123');
is $fake->last_call->{method}, 'delete', 'remove_reload_guide uses DELETE';
is $fake->last_call->{path}, '/livetv/dvrs/abc123/reloadGuide', 'remove_reload_guide path';

$livetv->epg_channelmap(source => 'guide');
is $fake->last_call->{path}, '/livetv/epg/channelmap?source=guide', 'epg_channelmap path';

$livetv->epg_country_lineups('us', 'guide1', include => 'all');
is $fake->last_call->{path}, '/livetv/epg/countries/us/guide1/lineups?include=all', 'epg_country_lineups path';

$livetv->epg_country_region_lineups('us', 'guide1', 'midwest', camp => 'x');
is $fake->last_call->{path}, '/livetv/epg/countries/us/guide1/regions/midwest/lineups?camp=x', 'epg_country_region_lineups path';

$livetv->sessions(state => 'active');
is $fake->last_call->{path}, '/livetv/sessions?state=active', 'sessions path';

$livetv->session('sess1');
is $fake->last_call->{path}, '/livetv/sessions/sess1', 'session path';

$livetv->session_index('sess1', 'cons1', bitrate => 1000);
is $fake->last_call->{path}, '/livetv/sessions/sess1/cons1/index.m3u8?bitrate=1000', 'session_index path';

$livetv->session_segment('sess1', 'cons1', 'seg1');
is $fake->last_call->{path}, '/livetv/sessions/sess1/cons1/seg1', 'session_segment path';

done_testing;
