use v5.42;
use Test::More;
use Test::Exception;

use_ok('WebService::Plex');

# Good args
lives_ok {
    WebService::Plex->new(baseurl => 'http://x', token => 'abc');
} 'constructs with required args';

# Missing baseurl
dies_ok {
    WebService::Plex->new(token => 'abc');
} 'dies without baseurl';

# Missing token
dies_ok {
    WebService::Plex->new(baseurl => 'http://x');
} 'dies without token';

# Custom timeout
lives_ok {
    WebService::Plex->new(baseurl => 'http://x', token => 'abc', timeout => 99);
} 'constructs with custom timeout';

done_testing;