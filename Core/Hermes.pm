package Alcyon::Core::Hermes;

use strict;
use warnings;
use 5.010;

use Carp;
use YAML::XS 0.38;
use LWP::UserAgent 6.03;
use LWP::Protocol::https 6.03;
use HTML::Entities 3.69;

# Think at Term::ReadPassword if you want to dynamically ask the
# user its password (or if you don't want to store it in
# the code, which seems a perfect attitude to me).

our $VERSION = 1.2;

our $_instance = undef;
our %params    = ();

######################################################################

# Generate a closure.
sub get {
    my ( $class, %args ) = @_;
    our $_instance;

    unless ( defined $_instance and _same_params(%args) ) {
        $_instance = { verbose => $args{verbose} };
        bless $_instance => $class;
        $_instance->notice( 'generating a new instance of ' . ref $_instance );

        $_instance->{url} = $args{url} or croak "No URL provided!";
        $_instance->{tolerance} = $args{tolerance} // 5;
        ( $_instance->{domain} = $args{url} ) =~ s{
            ^ https? :// ( [^ / ]+ )
        }{lc $1}exi;

        $_instance->{ua} = LWP::UserAgent->new(
            agent =>
"Hermes/$VERSION (Hyperion/6; +http://fr.vikidia.org/wiki/user:thilp)",
            from       => 'thilp.is@gmail.com',
            cookie_jar => { file => '.cookies.txt', autosave => 1 },
            max_size   => 2_000_000,
            timeout    => 10,
            protocols_allowed => [ 'http', 'https' ],
            ssl_opts => { verify_hostname => $args{certified} || 0 },

            # PROXY USERS: you might want to add some code here to set the proxy
            # options of LWP
        );

        if ( exists $args{username} and exists $args{password} )
        {    # authentified
            $_instance->notice('setting up an authentified connection');
            $_instance->{username} = $args{username};
            $_instance->_login( $args{password} );
        }
        else {    # anonymous connection
            $_instance->notice('setting up an anonymous connection');
        }

        %params = %args;
    }

    return sub {
        my $query = shift;
        return $_instance->_ask($query);
      }
}

######################################################################

# Check if the given hash has the same fields than the registered hash.
sub _same_params {
    my (%new_params) = @_;
    our %params;

    foreach my $k ( keys %params ) {
        return 0 if $params{$k} ne $new_params{$k};
    }

    return 1;
}

######################################################################

sub _login {
    my ( $self, $password ) = @_;

    return 0 unless exists $self->{username} and defined $password;

    my $answ = $self->_ask(
        action     => 'login',
        lgname     => $self->{username},
        lgpassword => $password
    );
    ################
    if ( $answ->{login}{result} eq 'Success' ) {
        $self->{sessionid} = $answ->{login}{sessionid};
        $self->notice("you are now logged in as $self->{username}");
    }
    ################
    elsif ( $answ->{login}{result} eq 'NeedToken' ) {
        $answ = $self->_ask(
            action     => 'login',
            lgname     => $self->{username},
            lgpassword => $password,
            lgtoken    => $answ->{login}{token}
        );
        if ( $answ->{login}{result} eq 'Success' ) {
            $self->{sessionid} = $answ->{login}{sessionid};
            $self->notice("you are now logged in as $self->{username}");
        }
        else {
            carp <<"EOF"; return 0;
Unable to log in with this (username,password) couple! Server answered:
$answ->{login}{result}
EOF
        }
    }
    ################
    else {
        carp <<"EOF"; return 0;
Unable to log in with this (username,password) couple! Server answered:
$answ->{login}{result}
EOF
    }

    # Get edit token.
    $answ = $self->_ask(
        action  => 'query',
        prop    => 'info',
        intoken => 'edit|delete|protect|move|block|unblock'
    );

    print Dump($answ);

    return 1;
}

######################################################################

sub _ask {
    my ( $self, %args ) = @_;

    if ( $args{transmission_html_encode} ) {
        delete $args{transmission_html_encode};
        %args = map( { encode_entities $_ } %args );
    }
    $args{format} = 'yaml';

    my $answer;
    my $attempts = 0;

    while ( $attempts < $self->{tolerance} ) {
        $answer = $self->{ua}->post(
            $self->{url},
            Content_Type => 'application/x-www-form-urlencoded',
            Content      => \%args
        );
        if ( $answer->is_success ) {

            # Directly returns the YAML structure loaded into
            # a Perl hash reference.
            ( my $r = $answer->decoded_content( raise_error => 1 ) ) =~
              s| \\/ |/|xg;
            eval { $r = Load($r) } or (carp <<"EOF"), return;
An error occurred while Load()ing the YAML into Perl:
$@
The server's answer was:
@{[ $answer->decoded_content() ]}
EOF
            return $r;
        }
        else {
            $self->notice( "warning: attempt "
                  . ( ++$attempts )
                  . "/$self->{tolerance} "
                  . "of ASK()ing your stuff failed so miserably! ("
                  . $answer->status_line
                  . ")" );
        }
    }

    # None of the $self->{tolerance} attempts has terminated correctly.
    $self->notice(<<'EOF');
Error: I have not been able to properly transfer the request
or to receive the API server's answer.
Returning UNDEF
EOF
    return;
}

######################################################################

sub notice {
    my $self = shift;
    return unless ( $self->{verbose} );
    print STDERR "\t\033[36mHermes::notice:\033[0m ", @_, "\n";
    return;
}

######################################################################

sub DESTROY {
    my $self = shift;
    $self->_ask( action => 'logout' );
    $self->notice("user $self->{username} logged out");
    return;
}

######################################################################

#
1;
__END__

=head1 NAME

Alcyon::Core::Hermes - Communicate with the MediaWiki API.

=head1 VERSION

This is version 1.2 of C<Alcyon::Core::Hermes>, dated November 16, 2012.

=head1 SYNOPSIS

    my $hermes = Alcyon::Core::Hermes->get(
        url => 'https://fr.vikidia.org/w/api.php',
        username => $pseudo,
        password => $pass
    );

    my $API_answer = $hermes->(
        action => 'query',
        ...
    );

=head1 DESCRIPTION

Hermes has been designed for efficiency, flexibility and ease of use. It
allows to I<perl>ishly query the MediaWiki API and get I<perl>ish answers;
that is, you give Perl data structures and get back Perl data structures,
although everything in between has nothing to do with Perl (HTTP, JSON, etc.).

The Hermes “object” you get (by calling get()) is actually not a real object
but a closure (i.e. a reference on a Perl subroutine with its own scope).
That's why you use it through this strange (but short and efficient) syntax:

    my $answer = $hermes->( %my_query );

=head1 SUBROUTINES/METHODS

=over

=item C<< get( url => $url, username => $uname, password => $upass
[, certified => 0 ] [, tolerance => 5 ] [, verbose => 0 ] ) >>

Hermes is a singleton; this method returns the only Hermes instance,
constructing it if needed. Parameters:

=over

=item url

The URL of the MediaWiki API to interact with.

=item username

(optional for an anonymous connection; mandatory for an authentified one)

The name of the account you want to connect to.

The MediaWiki can be as well accessed I<logged in> as I<anonymously>,
but some operations need you to be logged in to be performed.

=item password

(optional for an anonymous connection; mandatory for an authentified one)

The password of the account you want to connect to.

=item certified

(optional)

Checks the remote host certificate when this parameter is set to 1; ignores it
otherwise.

Since Alcyon has been designed for Vikidia, whose certificate is
auto-signed, the default value of this parameter is B<0>.

=item tolerance

(optional)

Number of times Hermes must try to transmit a request (in case of the first
attempt should fail). Defaults to 5.

=item verbose

(optional)

When set to I<true>, Hermes can display detailled warnings and error messages.
Defaults to 0 (I<false>).

=back

=item Using a Hermes closure

When you do:

    my $hermes = Alcyon::Core::Hermes->get( %params );

you get a closure in C<$hermes>. This closure allows you to send all your
requests to the API. It returns a (probably nested) Perl structure,
such as a hash or an array, containing the various pieces of the API's answer.

Use this closure as follow:

    my $answer = $hermes->( %args );

C<%args> contains the parameters of the call:
each parameter is passed as a "C<< key => value >>" row. All parameters are
described on the MediaWiki wiki: https://www.mediawiki.org/wiki/API; or
directly on your target wiki, by loading the API page in your Web browser
(for Vikidia: https://fr.vikidia.org/w/api.php).

In addition to the traditional API parameters, you can set (or explicitely
unset, if you want so) the `C<transmission_html_encode>' option so that the
characters are encoded with HTML::Entities; this is discouraged for
I<login> requests.

=back

=head1 DEPENDENCIES

=over

=item *

C<YAML::XS>, version 0.38 or later;

=item *

C<LWP::UserAgent>, version 6.03 or later;

=item *

C<LWP::Protocol::https>, version 6.03 or later;

=item *

C<HTML::Entities>, version 3.69 or later.

=back

=head1 AUTHOR

thilp <thilp.is@gmail.com>

=head1 LICENSE AND COPYRIGHT

This, as a part of Alcyon, is released under the GNU Public License
version 3 or later (Z<>https://www.gnu.org/licenses/gpl.html).
