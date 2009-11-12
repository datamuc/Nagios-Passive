package Nagios::Passive::Spool;

use strict;
use Moose;
use Carp;
use File::Temp;
use version; our $VERSION = qv('0.1');

my $TEMPLATE = "cXXXXXX";

has 'spool_dir' => ( is => 'ro', isa => 'Str', required => 1);
has 'checkresults_dir' => ( is => 'ro', isa => 'Str');

has 'file_time' => ( is => 'rw', isa => 'Int', default => time );
has 'host_name' => ( is => 'rw', isa => 'Str');
has 'service_description' => ( is => 'rw', isa => 'Str');
has 'check_type' => ( is => 'rw', isa => 'Int', default => 0);
has 'check_options' => ( is => 'rw', isa => 'Int', default => 0);
has 'scheduled_check' => ( is => 'rw', isa => 'Int', default => 0);
has 'latency' => ( is => 'rw', isa => 'Num', default => 0.2);
has 'start_time' => ( is => 'rw', isa => 'Num', default=>time .".0");
has 'finish_time' => ( is => 'rw', isa => 'Num', default=>time .".2");
has 'early_timeout' => ( is => 'rw', isa => 'Int', default=>0);
has 'exited_ok' => ( is => 'rw', isa => 'Int',default=>1);
has 'return_code' => ( is => 'rw', isa => 'Int',default=>0);

sub BUILD {
  my $self = shift;
  my $cd = $self->spool_dir . "/checkresults";
  unless( -d $cd ) {
    croak("$cd is not a directory");
  }
  $self->{checkresults_dir} = $cd;
};

sub get_tempfile {
  my $self = shift;
  my $fh = File::Temp->new(
    TEMPLATE => $TEMPLATE,
    DIR => $self->checkresults_dir,
  );
  $fh->unlink_on_destroy(1);
  return $fh;
}


1;
__END__
### Active Check Result File ###
file_time=1258065708

### Nagios Service Check Result ###
# Time: Thu Nov 12 23:41:48 2009
host_name=localhost
service_description=GLASSFISH
check_type=0
check_options=0
scheduled_check=1
reschedule_check=1
latency=0.043000
start_time=1258065708.44190
finish_time=1258065708.271862
early_timeout=0
exited_ok=1
return_code=3
output=JMX4PERL UNKNOWN - Cannot fetch performance data\nError while fetching http://localhost:8080/j4p/search/*%3Aj2eeType%3DJ2EEServer%2C* :\n\n500 Can't connect to localhost:8080 (connect: Connection refused)\n=================================================================\n\n

