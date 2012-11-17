package Alcyon::Object;

use strict;
use warnings;
use 5.010;

our $VERSION = 1.0;

=head1 NAME

Alcyon::Object - Any object

=head1 VERSION

This is version 1.0 of C<Alcyon::Object>, dated November 15, 2012.

=head1 SYNOPSIS

  my $anything = new Alcyon::Object;
  $anything->log "Writing in the log file!";

=head1 DESCRIPTION

This is the base class of the entire Alcyon object system.
Every object from Object::* inherit from Object itself, just because any
object “I<is an>” Object.

Apart from metaphysical considerations, deriving every object of the
object system from a unique class factorizes the code used for common tasks
such as log-writing and configuration information transmitting.

=cut

use Carp;
use Alcyon::Core::Axiom 1.0;
use Alcyon::Core::Hermes 1.2;

=pod #########################################################################

=head1 SUBROUTINES/METHODS

=over

=item C<new()>

The creator.

Links the object with the configuration informations from
Alcyon::Core::Axiom.

=cut

sub new {
    my $class = shift;
    my $self  = {
        config => Alcyon::Core::Axiom->get,
        api    => Alcyon::Core::Hermes->get
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

sub log ($@) {
    my $self = shift;

    open my $fh, '>>', $self->{config}{logfile}
      or croak "Can't open the log file for writing!";

    say {$fh} time, ':', @_;

    return 1;
}

=pod #########################################################################

=item C<mediawiki(%args)>

Call the MediaWiki's API directly from this object thru the Hermes object
it contains.

=cut

sub mediawiki {
    my $self = shift;
    return $self->{api}->(@_);
}

=back

=head1 BUGS

None known.

=head1 AUTHOR

thilp <thilp.is@gmail.com>

=cut

1;
