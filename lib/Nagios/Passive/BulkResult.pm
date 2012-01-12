package Nagios::Passive::BulkResult;
use IO::File;
use File::Temp;
use Moose;

has 'checkresults_dir' => ( is => 'ro', isa => 'Str', required => 1);
has rpobjects => (
  is => 'rw',
  isa => 'ArrayRef[Nagios::Passive::ResultPath]',
  traits => ['Array'],
  default => sub { [] },
  handles => {
    add => 'push',
  },
);

with 'Nagios::Passive::Role::Tempfile';


sub submit {
  my $self = shift;

  # nothing to do if empty
  return unless @{$self->rpobjects};

  my $fh = $self->tempfile;

  print $fh "### Active Check Result File ###\n";
  print $fh sprintf("file_time=%d\n\n",time);

  for my $rp (@{ $self->rpobjects }) {
    my $output = $rp->_to_string;
    $fh->print($output) or croak($!);
  }

  $self->_touch_file;

  return $fh->filename;
}

1;
__END__
