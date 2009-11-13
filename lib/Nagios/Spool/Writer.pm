package Nagios::Spool::Writer;

use strict;
use Moose;
use Carp;
use File::Temp;
use Fcntl;
use version; our $VERSION = qv('0.0.1');

my $TEMPLATE = "cXXXXXX";

has 'checkresults_dir'    => ( is => 'ro', isa => 'Str', required => 1);

has 'file_time'           => ( is => 'rw', isa => 'Int', default => time );
has 'host_name'           => ( is => 'rw', isa => 'Str');
has 'service_description' => ( is => 'rw', isa => 'Str');
has 'check_type'          => ( is => 'rw', isa => 'Int', default => 0);
has 'check_options'       => ( is => 'rw', isa => 'Int', default => 0);
has 'scheduled_check'     => ( is => 'rw', isa => 'Int', default => 0);
has 'latency'             => ( is => 'rw', isa => 'Num', default => 0);
has 'start_time'          => ( is => 'rw', isa => 'Num', default=>(time-1) .".0");
has 'finish_time'         => ( is => 'rw', isa => 'Num', default=>(time-1) .".2");
has 'early_timeout'       => ( is => 'rw', isa => 'Int', default=>0);
has 'exited_ok'           => ( is => 'rw', isa => 'Int', default=>1);
has 'return_code'         => ( is => 'rw', isa => 'Int', default=>0);
has 'output'              => ( is => 'rw', isa => 'Str');

sub BUILD {
  my $self = shift;
  my $cd = $self->checkresults_dir;
  croak("$cd is not a directory") unless(-d $cd);
};

sub get_tempfile {
  my $self = shift;
  my $fh = File::Temp->new(
    TEMPLATE => $TEMPLATE,
    DIR => $self->checkresults_dir,
  );
  $fh->unlink_on_destroy(0);
  $self->{fh} = $fh;
  return $fh;
}

sub touch_file {
  my $self = shift;
  my $fh = $self->{fh};
  my $file = $fh->filename.".ok";
  sysopen my $t,$file,O_WRONLY|O_CREAT|O_NONBLOCK|O_NOCTTY
    or croak("Can't create $file : $!");
  close $t or croak("Can't close $file : $!");
}

sub write_file {
  my $self = shift;
  my $fh = $self->get_tempfile;
  print $fh "### Active Check Result File ###\n";
  print $fh 'file_time=',$self->file_time,"\n";
  print $fh "\n";
  print $fh "### Nagios Service Check Result ###\n";
  print $fh '# Time: ', scalar localtime $self->file_time, "\n";
  print $fh 'host_name=', $self->host_name, "\n";
  print $fh 'service_description=', $self->service_description, "\n";
  print $fh 'check_type=', $self->check_type, "\n";
  print $fh 'check_options=', $self->check_options, "\n";
  print $fh 'scheduled_check=', $self->scheduled_check, "\n";
  print $fh 'latency=', $self->latency, "\n";
  print $fh 'start_time=', $self->start_time, "\n";
  print $fh 'finish_time=', $self->finish_time, "\n";
  print $fh 'early_timeout=', $self->early_timeout, "\n";
  print $fh 'exited_ok=', $self->exited_ok, "\n";
  print $fh 'return_code=', $self->return_code, "\n";
  print $fh 'output=', $self->output, "\n";
  $self->touch_file;
  return $fh->filename;
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

