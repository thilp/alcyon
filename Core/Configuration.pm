package Configuration;

use strict;
use warnings;
use v5.10;


my %dispatch = (
  LOG		=> '$self->{logfile} = $arg',
  DATABASE	=> '$self->{dbfile} = $arg',
  _DEFAULT	=> 'warn "Ignoring unknown `$instr\' instruction.\n"',
);

my @mandatory = (
  'DATABASE'
);

my %defaults = (
  LOG		=> 'default.log',
);

sub new
{
  my $class = shift;
  my $self = {};

  my %viewed;

  # Read the file and set the mentionned options.
  my $filename = glob '*.cfg' or die "Can't find a .cfg configuration file!";
  open my $FILE, '<', $filename or die "Unable to open $filename for reading!";
  while (<$FILE>)
  {
    chomp;
    my ($instr, $arg) = $_ =~ /^(\p{Lu}+)\s+(.+)$/;
    my $action = $dispatch{$instr} || $dispatch{_DEFAULT};
    eval $action;
    $viewed{$instr} = 1;
  }

  # Check that all the mandatory options have been set.
  foreach (@mandatory)
  {
    die "Mandatory option `$_' omitted in $filename!\n" unless $viewed{$_};
  }

  # Set default value for unseen, non-mandatory options.
  my $arg;
  foreach (keys %defaults)
  {
    unless ($viewed{$_})
    {
      $arg = $defaults{$_};
      eval $dispatch{$_};
    }
  }

  bless $self, $class;
  return $self;
}

#
1;
