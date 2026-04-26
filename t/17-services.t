use v5.42;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

use FakePlex;
use WebService::Plex::Services;

my $fake     = FakePlex->new;
my $services = WebService::Plex::Services->new(plex => $fake);

$services->ultrablur_colors(format => 'json');
is $fake->last_call->{method}, 'get', 'ultrablur_colors uses GET';
is $fake->last_call->{path}, '/services/ultrablur/colors?format=json', 'ultrablur_colors path';

$services->ultrablur_image(width => 200, height => 200);
is $fake->last_call->{path}, '/services/ultrablur/image?height=200&width=200', 'ultrablur_image path';

done_testing;
