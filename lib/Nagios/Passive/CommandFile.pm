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
  flock($f, LOCK_EX) or croak("cannot get lock on $cf: $!");
  print $f $output;
  flock($f, LOCK_UN) or croak("cannot unlock $cf: $!");
  close($f) or croak("cannot close $cf");
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Nagios::Passive::CommandFile - drop check results into Nagios' check_result_path.

=head1 SYNOPSIS

  my $nw = Nagios::Passive->create(
    command_file => $checkresultsdir,
    service_description => $service_description,
    check_name => $check_name,
    host_name  => $hostname,
    return_code => 0, # 1 2 3 
    output => 'looks (good|bad|horrible) | performancedata'
  );
  $nw->submit;

=head1 DESCRIPTION

This module gives you the ability to drop checkresults into
Nagios' external_command_file.

The usage is described in L<Nagios::Passive>

=cut
