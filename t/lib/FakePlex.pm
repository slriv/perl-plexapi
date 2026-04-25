use v5.42;
use experimental 'class';

class FakePlex {
    field @_log;

    method last_call { $_log[-1] }
    method reset     { @_log = () }

    method get ($path, %params) {
        push @_log, { method => 'get', path => $path, params => \%params };
        return {};
    }
    method put ($path) {
        push @_log, { method => 'put', path => $path };
        return 1;
    }
    method post ($path, %params) {
        push @_log, { method => 'post', path => $path, params => \%params };
        return {};
    }
    method delete ($path) {
        push @_log, { method => 'delete', path => $path };
        return 1;
    }
}

1;
