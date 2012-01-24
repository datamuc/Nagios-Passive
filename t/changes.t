#!perl

use Test::More;

(eval 'use Test::CPAN::Changes; 1' and $ENV{RELEASE_TESTING}) or
    plan skip_all => 'author test';
changes_file_ok("CHANGES");
done_testing;
