package Nagios::Passive::MKLivestatus;

use strict;
use Carp;
use Fcntl qw/:DEFAULT :flock/;
use Moose;
use Nagios::MKLivestatus;

extends 'Nagios::Passive::Base';

has 'socket'=>(
  is => 'rw',
  isa => 'Str',
  required => 1,
);

has '_live' => (
  is => 'rw',
  isa => 'Nagios::MKLivestatus',
  builder => '_build_live',
  lazy => 1,
);

sub _build_live {
  my $self = shift;
  my $socket = $self->socket;
  my $key = -S $socket ? 'socket' : 'server';
  return Nagios::MKLivestatus->new($key => $socket);
}

sub to_string {
  my $s = shift;
  my $output;
  if(defined $s->service_description) {
    $output = sprintf "COMMAND [%d] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s %s - %s",
      $s->time, $s->host_name, $s->service_description, $s->return_code,
      $s->check_name, $s->_status_code, $s->_quoted_output;
  } else {
    $output = sprintf "COMMAND [%d] PROCESS_HOST_CHECK_RESULT;%s;%d;%s %s - %s",
      $s->time, $s->host_name, $s->return_code,
      $s->check_name, $s->_status_code, $s->_quoted_output;
  }
  return $output;
}

sub submit {
  my $s = shift;
  my $live = $s->_live;
  $live->do($s->to_string);
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
