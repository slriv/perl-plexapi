use v5.42;
use experimental 'class';

our $VERSION = '0.01';

class WebService::Plex::Services {
    field $plex :param;

    method ultrablur_colors (%params) {
        $plex->get('/services/ultrablur/colors', %params);
    }

    method ultrablur_image (%params) {
        $plex->get('/services/ultrablur/image', %params);
    }
}

1;
__END__

=head1 NAME

WebService::Plex::Services - Plex auxiliary service endpoints

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $services = $plex->services;
  $services->ultrablur_colors(format => 'json');

=head1 DESCRIPTION

C<WebService::Plex::Services> exposes additional Plex service endpoints such
as UltraBlur image and color APIs.
