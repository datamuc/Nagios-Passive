use Test::More;

BEGIN {
use_ok( 'Nagios::Passive' );
use_ok( 'Nagios::Passive::Base' );
use_ok( 'Nagios::Passive::ResultPath' );
use_ok( 'Nagios::Passive::CommandFile' );
use_ok( 'Nagios::Passive::BulkResult' );
}

diag( "Testing Nagios::Passive $Nagios::Passive::VERSION" );

done_testing;
