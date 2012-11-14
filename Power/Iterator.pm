package Power::Iterator;


#------------------------------------------------------------------------
#
# Iterator
#
# Add semantics to the usage of iterators.
#
# This module is almost directly stolen from
# _Higher-Order Perl_, by Mark Jason Dominus.
#
#------------------------------------------------------------------------


use parent 'Exporter';

our @EXPORT = qw(Iterator pick);



### Get the next value from an iterator.
sub pick ($) { $_[0]->() }


### Easier-to-read iterator object. Use:
#     return Iterator { ... };
# instead of:
#     return sub { ... };
# This is basically just syntactic sugar.
sub Iterator (&) { return $_[0] }


### Re-implementation of the builtin map for the iterators. Same usage.
sub imap (&$)
{
  my ($transform, $iterator) = @_;
  return Iterator
  {
    local $_ = pick $iterator;
    return (defined $_ ? $transform->() : undef);
  };
}


### Re-implementation of the builtin grep for the iterators. Same usage.
sub igrep (&$)
{
  my ($criterion, $iterator) = @_;
  return Iterator
  {
    local $_;
    while (defined ($_ = pick $iterator))
    {
      return $_ if $criterion->();
    }
    return;
  };
}


### Given a list, builds the corresponding iterator.
sub list_to_iterator
{
  my @list = @_;
  return Iterator
  {
    return shift @list;
  };
}


### Concatenate an arbitrary number of given iterators.
sub icat ($@)
{
  my ($iterator, @iterators) = @_;
  my $item;
  return Iterator
  {
    until (defined ($item = pick $iterator))
    {
      $iterator = shift @iterators;
      return unless $iterator;
    }
    return $item;
  }
}

#
1;
