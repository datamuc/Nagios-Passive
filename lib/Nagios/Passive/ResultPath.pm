package Nagios::Passive::ResultPath;

use strict;
use Carp;
use File::Temp;
use Fcntl qw/:DEFAULT :flock/;
use Moose;

extends 'Nagios::Passive::Base';

my $TEMPLATE = "cXXXXXX";

has 'checkresults_dir'    => ( is => 'ro', isa => 'Str', required => 1);
has 'check_type'          => ( is => 'rw', isa => 'Int', default => 1);
has 'check_options'       => ( is => 'rw', isa => 'Int', default => 0);
has 'scheduled_check'     => ( is => 'rw', isa => 'Int', default => 0);
has 'latency'             => ( is => 'rw', isa => 'Num', default => 0);
has 'start_time'          => ( is => 'rw', isa => 'Num', default=>time . ".0");
has 'finish_time'         => ( is => 'rw', isa => 'Num', default=>time . ".0");
has 'early_timeout'       => ( is => 'rw', isa => 'Int', default=>0);
has 'exited_ok'           => ( is => 'rw', isa => 'Int', default=>1);
has 'command_file'=>(is => 'ro', isa => 'Str', predicate=>'has_command_file' );
has 'tempfile' => ( is => 'ro', isa => 'File::Temp', lazy_build => 1);

sub BUILD {
  my $self = shift;
  my $cd = $self->checkresults_dir;
  croak("$cd is not a directory") unless(-d $cd);
};

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
  $string.=sprintf "file_time=%d\n\n",$self->time;
  $string.="### Nagios Service Check Result ###\n";
  $string.=sprintf "# Time: %s\n",scalar localtime $self->time;
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

sub submit {
  my $self = shift;
  my $fh = $self->tempfile;
  print $fh $self->to_string;
  $self->_touch_file;
  return $fh->filename;
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
