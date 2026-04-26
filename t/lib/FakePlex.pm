use v5.42;
use experimental 'class';
use URI::Escape ();

class FakePlex {
    field $baseurl :param = 'http://fake.plex:32400';
    field $token   :param = 'faketoken';
    field @_log;

    method baseurl { $baseurl }
    method token   { $token }

    method last_call { $_log[-1] }
    method reset     { @_log = () }

    method _encode_params (%params) {
        return '' unless %params;
        return '?' . join('&', map { URI::Escape::uri_escape($_) . '=' . URI::Escape::uri_escape($params{$_}) } sort keys %params);
    }

    method _log_call ($method, $path, %params) {
        my $query = '';
        if ($method ne 'post' && $method ne 'post_abs') {
            $query = $self->_encode_params(%params);
        }
        push @_log, { method => $method, path => $path . $query, params => \%params };
    }

    method get ($path, %params) {
        $self->_log_call('get', $path, %params);
        return {};
    }
    method put ($path, %params) {
        $self->_log_call('put', $path, %params);
        return 1;
    }
    method post ($path, %params) {
        $self->_log_call('post', $path, %params);
        return {};
    }
    method delete ($path, %params) {
        $self->_log_call('delete', $path, %params);
        return 1;
    }

    # Absolute-URL variants (plex.tv, discover.provider.plex.tv, etc.)
    method get_abs ($url, %params) {
        $self->_log_call('get_abs', $url, %params);
        return {};
    }
    method post_abs ($url, %params) {
        $self->_log_call('post_abs', $url, %params);
        return {};
    }
    method put_abs ($url, %params) {
        $self->_log_call('put_abs', $url, %params);
        return 1;
    }
    method delete_abs ($url, %params) {
        $self->_log_call('delete_abs', $url, %params);
        return 1;
    }
}

1;
