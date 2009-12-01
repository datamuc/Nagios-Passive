#!perl
use Test::More;

plan skip_all => "author test" unless($ENV{TEST_AUTHOR});

eval 'use Test::Perl::Critic;';
if($@) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::Perl::Critic::all_critic_ok();
