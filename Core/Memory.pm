package Alcyon::Core::Memory;

use strict;
use warnings;
use 5.010;

use Carp;
use DBI 1.622;
use Alcyon::Core::Configuration 1.0;

our $VERSION = 1.0;

my $conf = Alcyon::Core::Axiom->get;
my %_handles;
my %_counts;

sub new {
    my $class = shift;
    my $self  = {};

    bless $self => $class;

    $self->{_dsn} = 'dbi:' . $conf->{dbtype} . ':dbname=' . $conf->{dbname};
    if ( $conf->{dbtype} ne 'SQLite' ) {
        $self->{_dsn} .= ';host=' . $conf->{dbhost};
    }

    $_handles{ $self->{_dsn} } = undef unless $_handles{ $self->{_dsn} };
    $_counts{ $self->{_dsn} }++;

    return $self;
}

sub handle {
    my $self = shift;
    my $dsn  = $self->{_dsn};

    unless ( defined $_handles{$dsn} ) {
        $_handles{$dsn} =
          DBI->connect( $dsn, $conf->{dbuser}, $conf->{dbpass},
            { AutoCommit => 1, RaiseError => 1 } )
          or carp "Unable to get the database handler: ", DBI::errstr;

        if ( $conf->{dbtype} eq 'mysql' ) {
            $_handles{$dsn}->{mysql_auto_reconnect} = 1;
        }
    }

    return $_handles{$dsn};
}

sub DESTROY {
    my $self = shift;
    my $dsn  = $self->{_dsn};

    $_counts{$dsn}--;

    if ( $_counts{$_dsn} == 0 and defined $_handles{$dsn} ) {
        $_handles{$dsn}->disconnect;
        delete $_handles{$dsn};
    }

    return;
}

1;
__END__

=head1 NAME

Alcyon::Core::Memory - A simple database handler.

=head1 VERSION

This is version 1.0 of C<Alcyon::Core::Memory>, dated November 13, 2012.

=head1 SYNOPSIS

    my $db = new Alcyon::Core::Memory;
    my $dbh = $db->handle;
    $dbh->do( ... );

=head1 DESCRIPTION

C<Core::Memory> is a wrapper around a database connection.
When called for the first time, it uses C<Core::Axiom> to get the database
informations and connects to it. Then, each time it is asked for a handle
object, it returns the one it has got at the beginning. When the last
C<Memory> object is lost, the corresponding database connection is cut.

C<Core::Memory> is DBMS-independent, although it has primarily been
designed to work with SQLite.

The design of C<Memory> allows it to maintain several connections to different
database servers at the same time, although it currently asks the connection
informations to C<Core::Axiom> only.

=head1 SUBROUTINES/METHODS

=over

=item new

Returns a new C<Memory> object.

=item handle

Returns a (C<DBI>) handle object corresponding to the database defined by
C<Memory> according to the current C<Axiom>.

=back

=head1 DEPENDENCIES

=over

=item *

C<DBI> (v1.622 or later);

=item *

C<Alcyon::Core::Axiom> (v1.0 or later).

=back

=head1 AUTHOR

thilp <thilp.is@gmail.com>

=head1 LICENSE AND COPYRIGHT

This, as a part of Alcyon, is released under the GNU Public License
version 3 or later (Z<>https://www.gnu.org/licenses/gpl.html).
