use Test::More;

plan skip_all => "author test" unless($ENV{TEST_AUTHOR});

eval {
  require Test::Kwalitee;
  Test::Kwalitee->import(
    tests => [qw/-has_test_pod_coverage/]
  )
};

diag($@);
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

