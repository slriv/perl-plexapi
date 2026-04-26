use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::LiveTV {
    use URI::Escape qw(uri_escape);

    field $plex :param;

    method dvrs (%params) {
        $plex->get('/livetv/dvrs', %params);
    }

    method create_dvr (%params) {
        $plex->post('/livetv/dvrs', %params);
    }

    method dvr ($dvr_id) {
        $plex->get("/livetv/dvrs/$dvr_id");
    }

    method delete_dvr ($dvr_id) {
        $plex->delete("/livetv/dvrs/$dvr_id");
    }

    method tune_channel ($dvr_id, $channel, %params) {
        $plex->post("/livetv/dvrs/$dvr_id/channels/$channel/tune", %params);
    }

    method dvr_device ($dvr_id, $device_id) {
        $plex->get("/livetv/dvrs/$dvr_id/devices/$device_id");
    }

    method update_dvr_device ($dvr_id, $device_id, %params) {
        $plex->put("/livetv/dvrs/$dvr_id/devices/$device_id", %params);
    }

    method delete_dvr_device ($dvr_id, $device_id) {
        $plex->delete("/livetv/dvrs/$dvr_id/devices/$device_id");
    }

    method dvr_lineups ($dvr_id, %params) {
        $plex->put("/livetv/dvrs/$dvr_id/lineups", %params);
    }

    method delete_dvr_lineups ($dvr_id, %params) {
        $plex->delete("/livetv/dvrs/$dvr_id/lineups", %params);
    }

    method dvr_prefs ($dvr_id, %params) {
        $plex->put("/livetv/dvrs/$dvr_id/prefs", %params);
    }

    method reload_guide ($dvr_id) {
        $plex->post("/livetv/dvrs/$dvr_id/reloadGuide");
    }

    method remove_reload_guide ($dvr_id) {
        $plex->delete("/livetv/dvrs/$dvr_id/reloadGuide");
    }

    method epg_channelmap (%params) {
        $plex->get('/livetv/epg/channelmap', %params);
    }

    method epg_channels (%params) {
        $plex->get('/livetv/epg/channels', %params);
    }

    method epg_countries (%params) {
        $plex->get('/livetv/epg/countries', %params);
    }

    method epg_country_lineups ($country, $epg_id, %params) {
        $plex->get("/livetv/epg/countries/$country/$epg_id/lineups", %params);
    }

    method epg_country_regions ($country, $epg_id, %params) {
        $plex->get("/livetv/epg/countries/$country/$epg_id/regions", %params);
    }

    method epg_country_region_lineups ($country, $epg_id, $region, %params) {
        $plex->get("/livetv/epg/countries/$country/$epg_id/regions/$region/lineups", %params);
    }

    method epg_languages (%params) {
        $plex->get('/livetv/epg/languages', %params);
    }

    method epg_lineup (%params) {
        $plex->get('/livetv/epg/lineup', %params);
    }

    method epg_lineupchannels (%params) {
        $plex->get('/livetv/epg/lineupchannels', %params);
    }

    method sessions (%params) {
        $plex->get('/livetv/sessions', %params);
    }

    method session ($session_id) {
        $plex->get("/livetv/sessions/$session_id");
    }

    method session_index ($session_id, $consumer_id, %params) {
        $plex->get("/livetv/sessions/$session_id/$consumer_id/index.m3u8", %params);
    }

    method session_segment ($session_id, $consumer_id, $segment_id, %params) {
        $plex->get("/livetv/sessions/$session_id/$consumer_id/$segment_id", %params);
    }
}

1;
__END__

=head1 NAME

WebService::Plex::LiveTV - Plex Live TV DVR and EPG endpoints

=head1 VERSION

0.01

=head1 DESCRIPTION

C<WebService::Plex::LiveTV> provides access to Plex Live TV and DVR endpoints,
including DVR management, EPG lookups, and active session inspection.
