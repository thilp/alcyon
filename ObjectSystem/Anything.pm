package ObjectSystem::Anything;

=head1 NAME

ObjectSystem::Anything - Anything

=head1 SYNOPSIS

  my $anything = ObjectSystem::Anything->new;
  $anything->log "Writing in the log file!";

=head1 DESCRIPTION

This is the base class of the entire ObjectSystem. Maybe it should have
been called ``ObjectSystem'' itself. Every object from ObjectSystem::*
inherit from ObjectSystem::Anything, simply because I<anything> in there
``is a'' Anything.

Apart from metaphysical considerations, deriving every object of the
object system from Anything factorizes the code used for common tasks
such as log-writing and configuration information transmitting.

=cut

use strict;
use warnings;
use v5.10;

use Carp;
use Core::Configuration;

=pod #########################################################################

=head1 FUNCTIONS

=over

=item C<new()>

The creator of Anything (what a pretty cool job).

Links the object with the configuration informations from
Core::Configuration.

=cut

sub new
{
  my $class = shift;
  my $self = {
    config	=> Core::Configuration->instance,
    api		=> Core::Hermes->instance
  };

  bless $self => $class;
  return $self;
}

=pod #########################################################################

=item C<log $text, ...>

Write any string given as argument at the end of the log file (defined in
Core::Configuration).

Dies if the log file can't be opened, otherwise returns always 1.

=cut

sub log ($@)
{
  my $self = shift;

  open my $fh, '>>', $self->{config}{logfile}
    or croak "Can't open the log file for writing!";

  say {$fh} time, ':', @_;

  return 1;
}

=pod #########################################################################

=item C<mediawiki(%args)>

A thin wrapper around the C<Core::Hermes::ask> method.

=cut

sub mediawiki
{
  my $self = shift;
  return $self->{api}->ask(@_);
}

=back

=head1 BUGS

None.

=head1 AUTHOR

Thibaut Le Page <thibaut.lepage@epita.fr>

=cut

1;
