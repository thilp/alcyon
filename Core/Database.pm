package Database;

use strict;
use warnings;
use v5.10;

use DBI;


sub new
{
  my ($class, $dbfilename) = @_;
  my $self = {};

  $self->{dbh} = DBI->connect(
    "dbi:SQLite:dbname=$dbfilename", "", "",
    { RaiseError => 1 }		# raise exceptions
  ) or return undef;

  return $self;
}


sub handler
{
  my $self = shift;

  return $self->{dbh};
}


sub DESTROY
{
  my $self = shift;
  $self->{dbh}->disconnect();
}

#
1;
