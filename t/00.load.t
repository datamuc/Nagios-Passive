use Test::More tests => 4;

plan skip_all => "MSWin32 not supported" if $^O eq 'MSWin32';

BEGIN {
use_ok( 'Nagios::Passive' );
use_ok( 'Nagios::Passive::ResultPath' );
use_ok( 'Nagios::Passive::CommandFile' );
use_ok( 'Nagios::Passive::BulkResult' );
}

diag( "Testing Nagios::Passive $Nagios::Passive::VERSION" );
