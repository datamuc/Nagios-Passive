#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
if ( $@ ) {
  plan skip_all => "Test::Pod 1.14 required for testing POD"
}
if(! $ENV{TEST_POD} ) {
  plan skip_all => 'set TEST_POD environment to run this test'
}
all_pod_files_ok();
