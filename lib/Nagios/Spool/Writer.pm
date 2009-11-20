package Nagios::Spool::Writer;

use strict;
use Carp;
use File::Temp;
use Fcntl qw/:DEFAULT :flock/;
use Nagios::Plugin::Threshold;
use Nagios::Plugin::Performance;
Nagios::Plugin::Functions::_use_die(1);
use version; our $VERSION = qv('0.1.0');
use overload '""' => \&to_string;
use Moose;

my $TEMPLATE = "cXXXXXX";
my %RETURN_CODES = (
  0 => 'OK',
  1 => 'WARNING',
  2 => 'CRITICAL',
  3 => 'UNKNOWN',
);

has 'checkresults_dir'    => ( is => 'ro', isa => 'Str', required => 1);
has 'check_name'	  => ( is => 'rw', isa => 'Str', required => 1);
has 'host_name'           => ( is => 'rw', isa => 'Str', required=>1);
has 'service_description' => ( is => 'rw', isa => 'Str');
has 'file_time'           => ( is => 'rw', isa => 'Int', default => time );
has 'check_type'          => ( is => 'rw', isa => 'Int', default => 1);
has 'check_options'       => ( is => 'rw', isa => 'Int', default => 0);
has 'scheduled_check'     => ( is => 'rw', isa => 'Int', default => 0);
has 'latency'             => ( is => 'rw', isa => 'Num', default => 0);
has 'start_time'          => ( is => 'rw', isa => 'Num', default=>time . ".0");
has 'finish_time'         => ( is => 'rw', isa => 'Num', default=>time . ".0");
has 'early_timeout'       => ( is => 'rw', isa => 'Int', default=>0);
has 'exited_ok'           => ( is => 'rw', isa => 'Int', default=>1);
has 'return_code'         => ( is => 'rw', isa => 'Int', default=>0);
has 'output'              => ( is => 'rw', isa => 'Str', default=>'no output');
has 'command_file'=>(is => 'ro', isa => 'Str', predicate=>'has_command_file' );
has 'tempfile' => ( is => 'ro', isa => 'File::Temp', lazy_build => 1);
has 'threshold'           => (
  is => 'ro',
  isa => 'Nagios::Plugin::Threshold',
  handles => [qw/set_thresholds/],
  lazy => 1,
  predicate => 'has_threshold',
  default => sub { Nagios::Plugin::Threshold->new },
);
has 'performance' => (
  traits => ['Array'],
  is => 'ro',
  isa => 'ArrayRef[Nagios::Plugin::Performance]',
  default => sub { [] },
  lazy => 1,
  predicate => 'has_performance',
  handles => {
     _performance_add => 'push',
  }
);

sub BUILD {
  my $self = shift;
  my $cd = $self->checkresults_dir;
  if($self->has_command_file) {
    my $cf = $self->command_file;
    croak("$cf is not a named pipe") unless (-p $cf);
  }
  croak("$cd is not a directory") unless(-d $cd);
};

sub add_perf {
  my $self = shift;
  my $perf = Nagios::Plugin::Performance->new(@_);
  $self->_performance_add($perf);
}

sub _build_tempfile {
  my $self = shift;
  my $fh = File::Temp->new(
    TEMPLATE => $TEMPLATE,
    DIR => $self->checkresults_dir,
  );
  $fh->unlink_on_destroy(0);
  return $fh;
}

sub _touch_file {
  my $self = shift;
  my $fh = $self->tempfile;
  my $file = $fh->filename.".ok";
  sysopen my $t,$file,O_WRONLY|O_CREAT|O_NONBLOCK|O_NOCTTY
    or croak("Can't create $file : $!");
  close $t or croak("Can't close $file : $!");
}

sub to_string {
  my $self = shift;
  my $string = "";
  $string.="### Active Check Result File ###\n";
  $string.=sprintf "file_time=%d\n\n",$self->file_time;
  $string.="### Nagios Service Check Result ###\n";
  $string.=sprintf "# Time: %s\n",scalar localtime $self->file_time;
  $string.=sprintf "host_name=%s\n", $self->host_name;
  if(defined($self->service_description)) {
    $string.=sprintf "service_description=%s\n", $self->service_description;
  }
  $string.=sprintf "check_type=%d\n", $self->check_type;
  $string.=sprintf "check_options=%d\n", $self->check_options;
  $string.=sprintf "scheduled_check=%d\n", $self->scheduled_check;
  $string.=sprintf "latency=%f\n", $self->latency;
  $string.=sprintf "start_time=%f\n", $self->start_time;
  $string.=sprintf "finish_time=%f\n", $self->finish_time;
  $string.=sprintf "early_timeout=%d\n", $self->early_timeout;
  $string.=sprintf "exited_ok=%d\n", $self->exited_ok;
  $string.=sprintf "return_code=%d\n", $self->return_code;
  $string.=sprintf "output=%s %s - %s\n", $self->check_name, 
             $self->_status_code, $self->_quoted_output;
  return $string;
}

sub write_file {
  my $self = shift;
  my $fh = $self->tempfile;
  print $fh $self->to_string;
  $self->_touch_file;
  return $fh->filename;
}

sub set_status {
  my $self = shift;
  my $value = shift;
  unless($self->has_threshold) {
    croak("you have to call set_thresholds before calling set_status");
  }
  $self->return_code($self->threshold->get_status($value))
}

sub _status_code {
  my $self = shift;
  my $r = $RETURN_CODES{$self->return_code};
  return defined($r) ? $r : 'UNKNOWN';
}

sub _quoted_output {
  my $self = shift;
  my $output = $self->output;
  # remove trailing newlines and quote the remaining ones
  $output =~ s/(?:\r?\n)*$//;
  $output =~ s/\n/\\n/g;
  if($self->has_performance) {
    return $output . " | ".$self->_perf_string;
  }
  return $output;
}

sub submit {
  my $s = shift;
  croak("no external_command_file given") unless $s->has_command_file;
  my $cf = $s->command_file;
  open(my $f, ">>", $cf) or croak("cannot open $cf: $!");  
  flock($f, LOCK_EX);
  $f->autoflush(1);
  # PROCESS_SERVICE_CHECK_RESULT;<host_name>;<svc_description>;<return_code>;<plugin_output>
  my $output = sprintf "[%d] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s %s - %s\n",
    $s->file_time, $s->host_name, $s->service_description, $s->return_code,
    $s->check_name, $s->_status_code, $s->_quoted_output;
  print $f $output;
  flock($f, LOCK_UN);
  close($f) or croak("cannot close $cf");
}

sub _perf_string {
  my $self = shift;
  return "" unless($self->has_performance);
  return join (" ", map { $_->perfoutput } @{ $self->performance });
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Nagios::Spool::Writer - drop check results into Nagios' check_result_path.

=head1 SYNOPSIS

  my $nw = Nagios::Spool::Writer->new(
    checkresults_dir => $checkresultsdir,
    service_description => $service_description,
    check_name => $check_name,
    host_name  => $hostname,
    return_code => 0, # 1 2 3 
    output => 'looks (good|bad|horrible) | performancedata'
  );
  $nw->write_file;

=head1 DESCRIPTION

This module gives you the ability to drop checkresults directly
into Nagios' check_result_path.

=head1 CONSTRUCTOR

=head2 new( %ARGS )

=over 4

=item checkresults_dir DIRECTORY

The directory where Nagios' configuration option `check_result_path'
points to.

=item hostname STRING

The hostname on which the check is bound to.

=item service_description STRING

The service description of the check. This is optional, if you
omit it, the result is treated as a check result for the host
check of hostname

=item check_name STRING

The name of the check. A nagios check typically returns a line as
follows:

  CHECKNAME STATUS - MESSAGE | PERFORMANCE_DATA

This method sets the value of CHECKNAME.

=item output STRING

This sets the text after the dash of the nagios output. (see
check_name).

=item return_code NUMBER

=over 8

=item 0 - OK

=item 1 - WARNING

=item 2 - CRITICAL

=item 3 - UNKNOWN

=back

This also sets the value of STATUS (see check_name).
It defaults to `0' if omited.

Instead of setting the return_code directly you can use set_thresholds
and set_status. (See METHODS).

=back

=head1 METHODS

=head2 set_thresholds HASH

This set's up an Nagios::Plugin::Threshold object.

  $ns->set_thresholds(
     warning => <rangespec>,
     critical => <rangespec>,
  );

For details see 
L<http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT>

=head2 set_status VALUE

Does value checking of VALUE against the threshold object created with
C<set_thresholds> and sets C<return_code> accordingly.

=head2 add_perf HASH

  $ns->add_perf(
     label => 'time',
     value => '0.1',
     uom   => 's',
  );

This adds Performance Data to the object. See
L<Nagios::Plugin::Performance> on how to use this. Finally the
performance data is appended to the end of C<output>. Can
be called multiple times to add more performance data.

=head2 write_file

Write the check_result into Nagios' check_result_path.

=head1 LIMITATIONS

This module is in an early stage of development, the API is
likely to brake in the future.

Also it interacts with an undocumented feature of Nagios. This
feature may disappear in the future.

=head1 DEVELOPMENT

Development takes place on github:

L<http://github.com/datamuc/Nagios-Spool-Writer>

=head1 AUTHOR

Danijel Tasov, <data@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009, Danijel Tasov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
