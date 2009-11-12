#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
if ( $@ ) {
  plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
}
if (! $ENV{TEST_POD} ) {
  plan skip_all => "set TEST_POD environment to run this test"
}
all_pod_coverage_ok();
