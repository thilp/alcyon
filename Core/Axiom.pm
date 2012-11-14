package Alcyon::Core::Axiom;

use strict;
use warnings;
use 5.010;

use Carp;

our $VERSION = 1.0;

my %dispatch = (
    _DEFAULT => sub {
        my $instr = shift;
        carp "Ignoring unknown `$instr' instruction.\n";
    }
);

my %setable = (
    LOG    => 1,
    DBTYPE => 1,
    DBNAME => 1,
    DBHOST => 1,
    DBUSER => 1,
    DBPASS => 1,
    DBPORT => 1,
);

my @mandatory = ( 'DBTYPE', 'DBNAME' );

my %defaults = (
    LOG    => 'default.log',
    DBHOST => 'localhost',
    DBUSER => '',
    DBPASS => '',
);

my $_conf = undef;

sub _set {
    my ( $instr, $h, $value ) = @_;

    if ( $setable{$instr} ) {
        $h->{ lc $instr } = $value;
        return;
    }

    if ( exists $dispatch{$instr} ) {
        return &{ $dispatch{$instr} }( $h, $value );
    }
    else {
        return &{ $dispatch{_DEFAULT} }($instr);
    }
}

sub get {
    my $class = shift;

    return $_conf if defined $_conf;

    $_conf = {};

    my %viewed;

    # Read the file and set the mentionned options.
    my $filename = glob '*.cfg'
      || croak "Can't find a .cfg configuration file!";
    open my $FILE, '<', $filename
      or croak "Unable to open $filename for reading!";
    while (<$FILE>) {
        chomp;
        my ( $instr, $arg ) = $_ =~ / ^ ( \p{Lu}+ ) \s+ ( .+ ) $ /x;
        _set( $instr, $_conf, $arg );
        $viewed{$instr} = 1;
    }
    close $FILE or carp "Can't correctly close $filename!";

    # Check that all the mandatory options have been set.
    foreach (@mandatory) {
        croak "Mandatory option `$_' omitted in $filename!\n"
          unless $viewed{$_};
    }

    # Set default value for unseen, non-mandatory options.
    my $arg;
    foreach ( keys %defaults ) {
        unless ( $viewed{$_} ) {
            $arg = $defaults{$_};
            _set( $_, $_conf, $arg );
        }
    }

    bless $_conf => $class;

    return $_conf;
}

sub list {
    return unless defined $_conf;
    return keys $_conf;
}

1;
__END__

=head1 NAME

Alcyon::Core::Axiom - Reads and stores the configuration variables.

=head1 VERSION

This is version 1.0 of Alcyon::Core::Axiom, dated November 13, 2012.

=head1 SYNOPSIS

    my $config = Alcyon::Core::Axioms->get;
    my $variables_list = Alcyon::Core::Axiom->list;

=head1 DESCRIPTION

This object is used to read (once) the Alcyon's configuration file and
access easily to the data it defines.

Basically, a hash is stored inside the class. When you use C<get>:

=over

=item if this hash has already been defined

Axiom returns it;

=item else

it is created by opening the first configuration file found in the current
directory and mapping the variables it defines.

=back

=head1 SUBROUTINES/METHODS

=over

=item C<get>

Returns the hash containing the variables set in the configuration file.

=item C<list>

Returns the list of variables' names (the keys of what is returned by C<get>).

=back

=head1 CONFIGURATION AND ENVIRONMENT

The construction of this object will die if there is no readable file
with `.cfg' extension. If there is more than one such file, the first
returned by the C<glob> function will be used.

=head1 DEPENDENCIES

None.

=head1 AUTHOR

thilp <thilp.is@gmail.com>

=head1 LICENSE AND COPYRIGHT

This, as a part of Alcyon, is released under the GNU Public License
version 3 or later (Z<>https://www.gnu.org/licenses/gpl.html).
