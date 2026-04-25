use v5.42;
use Test::More;
use Test::Exception;
use Test::MockModule;

use_ok('WebService::Plex');

# We'll capture the last URL used by the fake UA
my $last_url;
my $last_headers;

# Fake LWP::UserAgent
my $mock_ua = Test::MockModule->new('LWP::UserAgent');
$mock_ua->redefine(new => sub {
    my ($class, %args) = @_;
    my $obj = bless { %args }, $class;
    $obj;
});
$mock_ua->redefine(default_header => sub {
    my ($self, $k, $v) = @_;
    $last_headers->{$k} = $v if @_ == 3;
});
$mock_ua->redefine(get => sub {
    my ($self, $url) = @_;
    $last_url = $url;
    # Always return a successful HTTP::Response with JSON
    require HTTP::Response;
    return HTTP::Response->new(200, 'OK', [], '{"ok":1}');
});

my $plex = WebService::Plex->new(baseurl => 'http://host:1', token => 'tok');

# Simple GET
$plex->get('/identity');
like($last_url, qr{^http://host:1/identity$}, 'simple GET URL');

# GET with query params (order not guaranteed)
$plex->get('/foo', a => 'b', c => 'd');
my %qs = map { split /=/, $_, 2 } (split /[&?]/, $last_url)[1..($last_url =~ tr/&/&/ + 1)];
is($qs{a}, 'b', 'query param a=b');
is($qs{c}, 'd', 'query param c=d');

# GET with escaping
$plex->get('/bar', weird => 'a b&c=d');
like($last_url, qr{weird=a%20b%26c%3Dd}, 'query param is URI-escaped');

# GET with key escaping
$plex->get('/baz', 'a b' => 'x');
like($last_url, qr{a%20b=x}, 'query key is URI-escaped');

done_testing;