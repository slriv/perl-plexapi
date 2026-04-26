use v5.42;
use Test::More;
use File::Spec;

my $make = $ENV{MAKE} // 'make';

# Ensure Makefile exists -- generate it if needed
unless (-f 'Makefile') {
    system($^X, 'Makefile.PL') == 0
        or BAIL_OUT "perl Makefile.PL failed -- cannot test Makefile targets";
}

my $mk = do {
    open my $fh, '<', 'Makefile'
        or BAIL_OUT "Cannot read Makefile: $!";
    local $/; <$fh>
};

# --- Custom targets ---------------------------------------------------------
my @custom = qw(help test_integration plex_start plex_stop plex_reset);
ok $mk =~ /^\Q$_\E\b/m, "custom target '$_' present" for @custom;

# --- Standard EUMM targets --------------------------------------------------
my @standard = qw(all test install clean realclean dist distcheck manifest);
ok $mk =~ /^\Q$_\E\b/m, "standard target '$_' present" for @standard;

# --- help is our output, not perldoc ----------------------------------------
unlike $mk, qr/^help\b[^\n]*\n\tperldoc\b/m,
    'help target does not invoke perldoc';
like $mk, qr/test_integration/,
    'help output mentions test_integration';
like $mk, qr/plex_start/,
    'help output mentions plex_start';

# --- realclean must not touch source files ----------------------------------
my ($rc_recipe) = $mk =~ /^realclean\b[^\n]*\n((?:\t[^\n]*\n)*)/m;
$rc_recipe //= '';
unlike $rc_recipe, qr{\bt/},   'realclean recipe does not reference t/';
unlike $rc_recipe, qr{\blib/}, 'realclean recipe does not reference lib/';

# --- clean must not touch source files --------------------------------------
my ($c_recipe) = $mk =~ /^clean\b[^\n]*\n((?:\t[^\n]*\n)*)/m;
$c_recipe //= '';
unlike $c_recipe, qr{\bt/\d},          'clean recipe does not reference t/*.t';
unlike $c_recipe, qr{\blib/WebService}, 'clean recipe does not reference lib/WebService';

# --- make all builds blib ---------------------------------------------------
is system("$make all >/dev/null 2>&1"), 0, 'make all exits 0';
ok -f File::Spec->catfile(qw(blib lib WebService Plex.pm)),
    'blib/lib/WebService/Plex.pm present after make all';

# --- make help runs and shows expected content ------------------------------
my $help = qx($make help 2>&1);
like   $help, qr/WebService::Plex/,  'make help shows module name';
like   $help, qr/test_integration/,  'make help shows test_integration';
like   $help, qr/plex_start/,        'make help shows plex_start';
unlike $help, qr/perldoc/,           'make help does not show perldoc';

# --- make clean leaves source intact ----------------------------------------
# Note: EUMM's clean intentionally moves Makefile -> Makefile.old; that is
# expected and correct.  Only source files (t/, lib/, Makefile.PL) must survive.
is system("$make clean >/dev/null 2>&1"), 0, 'make clean exits 0';
ok -f 't/00-load.t',            't/00-load.t survives make clean';
ok -f 'lib/WebService/Plex.pm', 'lib/WebService/Plex.pm survives make clean';
ok -f 'Makefile.PL',            'Makefile.PL survives make clean';
ok -f 'Makefile.old',           'Makefile moved to Makefile.old by clean';
ok !-f 'blib',                  'blib/ removed by make clean';

# Rebuild: clean moves Makefile away so we must regenerate it first
is system("$^X Makefile.PL >/dev/null 2>&1"), 0, 'perl Makefile.PL regenerates after clean';
is system("$make all >/dev/null 2>&1"),        0, 'make all rebuilds after clean';

done_testing;
