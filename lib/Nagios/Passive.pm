package Nagios::Passive;
use Class::MOP;

sub create {
  my $this = shift;
  my %opts = ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;
  my $class;
  if($opts{command_file}) {
    $class = 'Nagios::Passive::CommandFile';
    Class::MOP::load_class($class);
  } else {
    $class = 'Nagios::Passive::ResultPath';
    Class::MOP::load_class($class);
  }
  return $class->new(%opts);
}
1;
