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

# Empty string baseurl
dies_ok {
    WebService::Plex->new(baseurl => '', token => 'abc');
} 'dies with empty baseurl';

# Token is optional (unclaimed local server)
lives_ok {
    WebService::Plex->new(baseurl => 'http://x');
} 'constructs without token (unclaimed server)';

lives_ok {
    WebService::Plex->new(baseurl => 'http://x', token => '');
} 'constructs with empty token';

# Custom timeout
lives_ok {
    WebService::Plex->new(baseurl => 'http://x', token => 'abc', timeout => 99);
} 'constructs with custom timeout';

done_testing;