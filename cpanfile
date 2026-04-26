requires 'perl', '5.042000';

# Optional: required only for WebService::Plex::Alert (WebSocket listener)
recommends 'AnyEvent';
recommends 'AnyEvent::WebSocket::Client';

requires 'Carp';
requires 'HTTP::Request';
requires 'JSON::XS';
requires 'LWP::UserAgent';
requires 'URI::Escape';

on test => sub {
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Test::MockModule';
    requires 'Test::LWP::UserAgent';
    requires 'CPAN::Changes';
    requires 'YAML::XS';
    requires 'AnyEvent';
    requires 'AnyEvent::WebSocket::Client';
};