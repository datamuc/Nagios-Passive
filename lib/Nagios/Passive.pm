package Nagios::Passive;
use Class::MOP;

sub create {
  my $this = shift;
  my $backend = shift;
  my $class = 'Nagios::Passive::'. $backend;
  Class::MOP::load_class($class);
  return $class->new(@_); 
}
1;
