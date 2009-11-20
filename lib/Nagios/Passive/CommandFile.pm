package Nagios::Passive::CommandFile;

use strict;
use Carp;
use Fcntl qw/:DEFAULT :flock/;
use Moose;

extends 'Nagios::Passive::Base';

has 'command_file'=>(
  is => 'ro',
  isa => 'Str',
  predicate=>'has_command_file'
);

sub BUILD {
  my $self = shift;
  my $cf = $self->command_file;
  croak("$cf is not a named pipe") unless (-p $cf);
};

sub to_string {
  my $s = shift;
  my $output;
  if(defined $s->service_description) {
    $output = sprintf "[%d] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s %s - %s\n",
      $s->time, $s->host_name, $s->service_description, $s->return_code,
      $s->check_name, $s->_status_code, $s->_quoted_output;
  } else {
    #PROCESS_HOST_CHECK_RESULT;<host_name>;<host_status>;<plugin_output>
    $output = sprintf "[%d] PROCESS_HOST_CHECK_RESULT;%s;%d;%s %s - %s\n",
      $s->time, $s->host_name, $s->return_code,
      $s->check_name, $s->_status_code, $s->_quoted_output;
  }
  return $output;
}

sub submit {
  my $s = shift;
  croak("no external_command_file given") unless $s->has_command_file;
  my $cf = $s->command_file;
  my $output = $s->to_string;
  open(my $f, ">>", $cf) or croak("cannot open $cf: $!");  
  $f->autoflush(1);
  flock($f, LOCK_EX);
  print $f $output;
  flock($f, LOCK_UN);
  close($f) or croak("cannot close $cf");
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
