package Alcyon::Core::Hermes::Lazy;

use strict;
use warnings;
use 5.010;

use Carp;
use DateTime 0.76;

our $DEFAULT_TIMEOUT = 1800;    # half an hour

sub new ($$%) {
    my ($class, $id, $codeblock, %query) = @_;
    my $self = { id => $id };

    $self->{timeout} = $query{timeout} || $DEFAULT_TIMEOUT;
    delete $query{timeout};

    $self->{extract} = $codeblock;
    $self->{query} = \%query;

    bless $self => $class;
    return $self;
}
