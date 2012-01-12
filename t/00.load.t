use Test::More tests => 4;

BEGIN {
use_ok( 'Nagios::Passive' );
use_ok( 'Nagios::Passive::ResultPath' );
use_ok( 'Nagios::Passive::CommandFile' );
use_ok( 'Nagios::Passive::BulkResult' );
}

diag( "Testing Nagios::Passive $Nagios::Passive::VERSION" );
