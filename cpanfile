requires 'perl', '5.042000';

requires 'Carp';
requires 'HTTP::Request';
requires 'JSON::XS';
requires 'LWP::UserAgent';
requires 'URI::Escape';

on test => sub {
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Test::MockModule';
};