package Alcyon::Core::Hermes::Lazy;

use strict;
use warnings;
use 5.010;

our $VERSION = 1.0;

=head1 NAME

Alcyon::Core::Hermes::Lazy - Piece of Lazyness.

=head1 VERSION

This is version 1.0 of C<Alcyon::Core::Hermes::Lazy>, dated November 20, 2012.

=head1 SYNOPSIS

    my $lazy = Alcyon::Core::Hermes->lazy
        {
            # "extractor code"
            # this code extracts the user-interesting data
        }
        %params;

    # returns the API's answer (which has gone through the extractor code)
    my $answer = $lazy->get;

=head1 DESCRIPTION

This class has been designed to closely work with Alcyon::Core::Hermes.
It allows it to do lazy requests to the MediaWiki API.

See the B< I<lazy> method> in the Alcyon::Core::Hermes documentation.

=head1 DEPENDENCIES

    Alcyon::Core::Hermes 1.2

=cut

use Alcyon::Core::Hermes 1.2;

=head1 SUBROUTINES/METHODS

=over

=item C<new( $id, $codeblock, $timeout, %query )>

Returns a new Alcyon::Core::Hermes::Lazy object.

C<$id> is the ID of this object; this ID is chosen by Hermes::lazy() and is
used to locate a given Lazy object regarding only its %query.

C<$codeblock> is a subroutine used to perform extraction on the fetched data.
Indeed, one is generally interested in only a I<part> of the structure
produced as an API answer: the C<$codeblock> performs a silent filtering,
thus allowing the Lazy object to be used almost as the extracted data itself.

C<$timeout> is the number of seconds the last fetched data is considered
valid and thus can be stocked in the cache. If the data is requested
(thru get()) after this timeout has expired, Lazy does not returns what is
still in the cache but uses Hermes to get fresh data instead.

C<%query> is a regular query to be provided to the MediaWiki API.

=cut

sub new {
    my ( $class, $id, $codeblock, $timeout, %query ) = @_;
    my $self = { id => $id };

    $self->{extract}     = $codeblock;
    $self->{query}       = \%query;
    $self->{timeout}     = $timeout;
    $self->{last_update} = 0;
    $self->{content}     = undef;
    $self->{hermes}      = Alcyon::Core::Hermes->get;

    bless $self => $class;
    return $self;
}

=item C<adapt_timeout( $new_timeout )>

One Lazy object may be shared among several identical queries, but
the queries' author may want them to be refreshed according to different
timeouts.

So, each time a Lazy object is linked to a new query, its timeout is updated
so that it equals the minimum of the timeouts of the related queries. This
is done with adapt_timeout(), which sets the object's timeout to
C<$new_timeout> only if C<$new_timeout> is smaller.

Besides, this methods returns the new (maybe changed) value of the object's
timeout.

=cut

sub adapt_timeout {
    my ( $self, $new_timeout ) = @_;

    $self->{timeout} = $new_timeout if $new_timeout < $self->{timeout};

    return $self->{timeout};
}

=item C<get()>

Returns the API's answer for the request corresponding to the current Lazy
object, after this answer has been filtered by the extractor code (see new()).

This answer is got from the object's cache unless the timeout (see new())
has expired, in which case Hermes is used to really query the MediaWiki API.

=cut

sub get {
    my $self = shift;
    $self->_update if ( $self->{last_update} + $self->{timeout} < time );
    return $self->{content};
}

# Update the last answer.
sub _update {
    my $self = shift;
    $self->{content} = $self->{hermes}->( $self->{query} );
    return;
}

1;
__END__

=back

=head1 AUTHOR

thilp <thilp.is@gmail.com>

=head1 LICENSE AND COPYRIGHT

This, as a part of Alcyon, is released under the GNU Public License
version 3 or later (Z<>https://www.gnu.org/licenses/gpl.html).
