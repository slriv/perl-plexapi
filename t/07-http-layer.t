use v5.42;
use Test::More;
use Test::Exception;
use Test::MockModule;
use Test::LWP::UserAgent;
use HTTP::Response;
use HTTP::Headers;

use WebService::Plex;

# ---------------------------------------------------------------------------
# Inject Test::LWP::UserAgent so WebService::Plex never hits the network.
# We return a single shared instance; each test section configures $next_res.
# ---------------------------------------------------------------------------

my ($next_res, $captured_req);
my $test_ua = Test::LWP::UserAgent->new(network_fallback => 0);
$test_ua->map_response(sub { $captured_req = $_[0]; 1 }, sub { $next_res });

my $mock_lwp = Test::MockModule->new('LWP::UserAgent');
$mock_lwp->redefine(new => sub { $test_ua });

my $plex = WebService::Plex->new(
    baseurl => 'http://plex.test:32400',
    token   => 'testtoken',
);

# ---------------------------------------------------------------------------
# _decode: HTTP error path
# ---------------------------------------------------------------------------

$next_res = HTTP::Response->new(401, 'Unauthorized', [], '');
throws_ok { $plex->get('/identity') }
    qr/HTTP error.*401/i,
    '_decode croaks with HTTP error on 401';

$next_res = HTTP::Response->new(404, 'Not Found', [], '');
throws_ok { $plex->get('/missing') }
    qr/HTTP error.*404/i,
    '_decode croaks with HTTP error on 404';

$next_res = HTTP::Response->new(500, 'Server Error', [], '');
throws_ok { $plex->get('/boom') }
    qr/HTTP error/i,
    '_decode croaks with HTTP error on 500';

# ---------------------------------------------------------------------------
# _decode: empty body returns true
# ---------------------------------------------------------------------------

$next_res = HTTP::Response->new(200, 'OK', [], '');
my $result;
lives_ok { $result = $plex->get('/no-body') } '_decode lives on empty body';
ok $result, '_decode returns true for empty body';

$next_res = HTTP::Response->new(200, 'OK', [], undef);
lives_ok { $result = $plex->put('/no-body') } '_decode lives on undef body (PUT)';
ok $result, '_decode returns true for undef body';

# ---------------------------------------------------------------------------
# _decode: valid JSON
# ---------------------------------------------------------------------------

$next_res = HTTP::Response->new(200, 'OK', [], '{"foo":"bar","n":42}');
lives_ok { $result = $plex->get('/good-json') } '_decode lives on valid JSON';
is ref($result), 'HASH',  '_decode returns hashref for JSON object';
is $result->{foo}, 'bar', '_decode decodes string value';
is $result->{n},   42,    '_decode decodes numeric value';

$next_res = HTTP::Response->new(200, 'OK', [], '[1,2,3]');
lives_ok { $result = $plex->get('/array-json') } '_decode lives on JSON array';
is ref($result), 'ARRAY', '_decode returns arrayref for JSON array';
is scalar @$result, 3,    '_decode decoded array length';

# ---------------------------------------------------------------------------
# _decode: invalid JSON (non-XML garbage)
# ---------------------------------------------------------------------------

$next_res = HTTP::Response->new(200, 'OK', [], 'not json {{{');
throws_ok { $plex->get('/bad-json') }
    qr/JSON parse error/,
    '_decode croaks on invalid JSON';

# ---------------------------------------------------------------------------
# _decode: XML response (client control) -- returns raw string, does not croak
# ---------------------------------------------------------------------------

my $xml = '<?xml version="1.0" encoding="UTF-8"?><Response code="200" status="OK"/>';
$next_res = HTTP::Response->new(200, 'OK', [], $xml);
my $raw;
lives_ok { $raw = $plex->get('/player/playback/play') } '_decode lives on XML response';
like $raw, qr{<Response},  '_decode returns raw XML string';
like $raw, qr{code="200"}, '_decode raw XML contains response code';

# ---------------------------------------------------------------------------
# Request headers
# ---------------------------------------------------------------------------

$next_res = HTTP::Response->new(200, 'OK', [], '{}');
$plex->get('/check-headers');

is $captured_req->header('X-Plex-Token'),    'testtoken',         'X-Plex-Token header';
is $captured_req->header('Accept'),          'application/json',  'Accept header';
ok $captured_req->header('X-Plex-Product'),                       'X-Plex-Product header present';
ok $captured_req->header('X-Plex-Version'),                       'X-Plex-Version header present';
ok $captured_req->header('X-Plex-Platform'),                      'X-Plex-Platform header present';

# ---------------------------------------------------------------------------
# HTTP methods: GET, POST, PUT, DELETE reach correct URL and method
# ---------------------------------------------------------------------------

$next_res = HTTP::Response->new(200, 'OK', [], '{}');

$plex->get('/library/sections');
is $captured_req->method,       'GET',                                'get uses GET';
is $captured_req->uri->path,    '/library/sections',                  'get path correct';
like $captured_req->uri->as_string, qr{^http://plex\.test:32400},    'get baseurl prepended';

$plex->get('/foo', a => '1', b => '2');
is $captured_req->method, 'GET', 'get with params uses GET';
my $qs = $captured_req->uri->query;
like $qs, qr{a=1},        'get query param a';
like $qs, qr{b=2},        'get query param b';

$next_res = HTTP::Response->new(200, 'OK', [], '{}');
$plex->post('/playlists', title => 'test');
is $captured_req->method,    'POST',        'post uses POST';
is $captured_req->uri->path, '/playlists',  'post path correct';

$next_res = HTTP::Response->new(200, 'OK', [], '');
$plex->put('/library/metadata/123/refresh');
is $captured_req->method,    'PUT',                          'put uses PUT';
is $captured_req->uri->path, '/library/metadata/123/refresh','put path correct';

$next_res = HTTP::Response->new(200, 'OK', [], '');
$plex->delete('/playlists/42');
is $captured_req->method,    'DELETE',       'delete uses DELETE';
is $captured_req->uri->path, '/playlists/42','delete path correct';

# ---------------------------------------------------------------------------
# Absolute-URL variants (used by MyPlex and Alert for plex.tv calls)
# ---------------------------------------------------------------------------

$next_res = HTTP::Response->new(200, 'OK', [], '{"ok":1}');
$plex->get_abs('https://plex.tv/api/v2/user');
is $captured_req->method,                 'GET',                      'get_abs uses GET';
is $captured_req->uri->as_string,         'https://plex.tv/api/v2/user', 'get_abs uses full URL';
ok !$captured_req->uri->query,            'get_abs with no params has no query string';

$plex->get_abs('https://plex.tv/api/v2/user', foo => 'bar');
like $captured_req->uri->as_string, qr{https://plex\.tv/api/v2/user\?}, 'get_abs appends query';
like $captured_req->uri->query,     qr{foo=bar},                         'get_abs query param';

$next_res = HTTP::Response->new(200, 'OK', [], '{}');
$plex->post_abs('https://plex.tv/api/v2/signin', user => 'test');
is $captured_req->method,       'POST',                       'post_abs uses POST';
is $captured_req->uri->host,    'plex.tv',                    'post_abs targets correct host';

$next_res = HTTP::Response->new(200, 'OK', [], '');
$plex->put_abs('https://plex.tv/some/resource');
is $captured_req->method,       'PUT',                        'put_abs uses PUT';
is $captured_req->uri->as_string, 'https://plex.tv/some/resource', 'put_abs full URL';

$plex->delete_abs('https://plex.tv/some/resource');
is $captured_req->method,       'DELETE',                     'delete_abs uses DELETE';
is $captured_req->uri->as_string, 'https://plex.tv/some/resource', 'delete_abs full URL';

# ---------------------------------------------------------------------------
# Connection info accessors
# ---------------------------------------------------------------------------

is $plex->baseurl, 'http://plex.test:32400', 'baseurl accessor';
is $plex->token,   'testtoken',              'token accessor';

# ---------------------------------------------------------------------------
# Submodule accessor caching
# ---------------------------------------------------------------------------

my $s1 = $plex->server;   my $s2 = $plex->server;
is $s1, $s2, 'server accessor returns cached instance';

my $l1 = $plex->library;  my $l2 = $plex->library;
is $l1, $l2, 'library accessor returns cached instance';

my $p1 = $plex->playlist; my $p2 = $plex->playlist;
is $p1, $p2, 'playlist accessor returns cached instance';

my $c1 = $plex->collection; my $c2 = $plex->collection;
is $c1, $c2, 'collection accessor returns cached instance';

done_testing;
