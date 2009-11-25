package Nagios::Passive;
require Class::MOP;

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
__END__

=head1 NAME

Nagios::Passive - drop check results into Nagios' check_result_path.

=head1 SYNOPSIS

  my $nw = Nagios::Passive->create(
    checkresults_dir => $checkresultsdir,
    service_description => $service_description,
    check_name => $check_name,
    host_name  => $hostname,
    return_code => 0, # 1 2 3 
    output => 'looks (good|bad|horrible) | performancedata'
  );
  $nw->submit;

=head1 DESCRIPTION

This is the factory class, currently it creates either a
Nagios::Passive::CommandFile or a Nagios::Passive::ResultPath object.
Which object is created depends on the keys you supply to the the create
method. The common interface to of the resulting objects is documented
in L<Nagios::Passive::Base>.

=head1 METHODS

=head2 create( %ARGS )

This method returns either a Nagios::Passive::CommandFile or
a Nagios::Passive::ResultPath object. If there is a key named
C<checkresults_dir> then a N::P::ResultPath object is created.
If there is a key C<command_file> a N::P::CommandFile object is
created.

=head1 LIMITATIONS

This module is in an early stage of development, the API is
likely to brake in the future.

Also it interacts with an undocumented feature of Nagios. This
feature may disappear in the future.

=head1 DEVELOPMENT

Development takes place on github:

L<http://github.com/datamuc/Nagios-Passive>

=head1 AUTHOR

Danijel Tasov, <data@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009, Danijel Tasov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
