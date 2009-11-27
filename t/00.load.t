use Test::More tests => 3;

BEGIN {
use_ok( 'Nagios::Passive' );
use_ok( 'Nagios::Passive::ResultPath' );
use_ok( 'Nagios::Passive::CommandFile' );
}

diag( "Testing Nagios::Passive $Nagios::Passive::VERSION" );
