package ObjectSystem::User;

=head1 NAME

ObjectSystem::User - Represents a contributor of Vikidia.

=head1 SYNOPSIS

  my $user = ObjectSystem::User->new(
    name => 'NewUser42',
    rank => IP
  );

=head1 DESCRIPTION

A User is an object able to modify Vikidia by making editorial changes
and interacting with other users.

=cut

use strict;
use warnings;
use v5.10;

=head1 INHERITANCE

  Anything
     |
   User

=cut

use mro 'c3';
use parent ('ObjectSystem::Anything');

=head1 CONSTANTS

This class defines several constants values representing the privileges
the user has been granted on Vikidia.

These constants are:

  IP
  USER
  PATROLLER
  ADMINISTRATOR
  ABUSEFILTER
  BUREAUCRAT
  DEVELOPER

=cut

use constant {
  IP		=> 1,
  USER		=> 2,
  PATROLLER	=> 3,
  ADMINISTRATOR	=> 4,
  ABUSEFILTER	=> 5,
  BUREAUCRAT	=> 6,
  DEVELOPER	=> 7
};

use DateTime;
use DateTime::Duration;

=pod #########################################################################

=head1 FUNCTIONS

=head2 BASICS

=over

=item C<< new(name => $uname, rank => $urank, born => $udate) >>

Constructor of the ObjectSystem::User object. This returns a new User whose
name is $uname (a string), whose rank is $urank (one of the constants
defined above) and which creation date is $udate (a DateTime object).

=cut

sub new
{
  my ($class, %args) = @_;

  croak "No name provided for the new User!" unless exists $args{name};
  croak "Unknown rank provided for the new User!"
    unless $args{rank} >= IP and $args{rank} <= DEVELOPER;
  croak "The `born' argument passed for the new User is not a DateTime!"
    unless ref $args{born} eq 'DateTime';

  my $self = next::method($class);

  $self->{name} = ucfirst $args{name};
  $self->{rank} = $args{rank}
  $self->{born} = $args{born};

  return $self;
}

=pod #########################################################################

=item ACCESSORS

The following methods set the related attribute to the value of their
argument (if any) and return the (modified or not) value of this attribute.

=over

=item C<name>

=cut

sub name
{
  my $self = shift;
  $self->{name} = shift if @_;
  return $self->{name};
}

=item C<rank>

=cut

sub rank
{
  my $self = shift;
  $self->{rank} = shift if @_;
  return $self->{rank};
}

=item C<born>

=cut

sub born
{
  my $self = shift;
  $self->{born} = shift if @_;
  return $self->{born};
}

=back ########################################################################

=item C<age()>

This method computes and returns the age of the User, in seconds.

=cut

sub age
{
  my $self = shift;
  my $now = DateTime->now;
  my $duration = $now->delta_ms($self->{born});
  return $duration->seconds;
}

=back ########################################################################

=head2 ACTIONS

These functions allow Alcyon to act directly on a User.

=over

=item C<< block(duration => $dur, reason => $str) >>

=cut

sub block
{
  my ($self, %args) = @_;

  my $token = $self->mediawiki(
    action	=> 'query',
    prop	=> 'info',
    intoken	=> 'block',
    titles	=> 'User:'.$self->{name}
  );
}

=back ########################################################################

=head1 BUGS

None.

=cut

1;
