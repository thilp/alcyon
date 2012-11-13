package Core::Hermes;

use strict;
use warnings;
use parent 'Class::Singleton';

use Carp;
use YAML::XS;
use LWP::UserAgent;
use HTML::Entities;
# In addition to the ones above, some modules are required:
#	- LWP::Protocol::https (if you choose this protocol in the URL
#		you give to Hermes);
#	- think at Term::ReadPassword if you want to dynamically ask the
#		user its password (or if you don't want to store it in
#		the code, which seems a perfect attitude to me).


our $VERSION = 1.0;

# CONSTRUCTOR
# Expected parameters:
#	- url: URL of the remote API;
#	- username: name of the user account we connect as;
#	- password: password of this user account;
#	- certified: (optional) check the remote host certificate
#		(default: 0);
#	- tolerance: (optional) how many times Hermes must try to execute
#		a request (in case of the first attempt should fail)
#		(default: 5);
#	- verbose: (optional) does Hermes display detailled
#		warning and error messages? (default: 0).
sub _new_instance
{
  my ($class, %args) = @_;
  my $self = {};

  $self->{url} = $args{url} or croak "No URL provided!";

  if (exists $args{username} and exists $args{password})
  { # authentified connection
    notice('setting up an authentified connection') if $args{verbose};
    $self->{username} = $args{username};
  }
  else
  { # anonymous connection
    notice('setting up an anonymous connection') if $args{verbose};
  }
  $self->{tolerance} = exists $args{tolerance} ? $args{tolerance} : 5;
  $self->{verbose} = $args{verbose};
  ($self->{domain} = $args{url}) =~ s%^https?://([^/]+)%$1%;
  $self->{ua} = LWP::UserAgent->new(
    agent	=> "Hermes/$VERSION (Hyperion/6; +http://fr.vikidia.org/wiki/user:thilp)",
    from	=> 'thilp.is@gmail.com',
    cookie_jar	=> { file => '.cookies.txt', autosave => 1 },
    max_size	=> 2000000,
    timeout	=> 10,
    protocols_allowed => [ 'http', 'https' ],
    ssl_opts	=> { verify_hostname => $args{certified} || 0 },
    # PROXY USERS: you might want to add some code here to set the proxy
    # options of LWP
  );
  bless $self, $class;

  # Login
  if (exists $self->{username})
  {
    my $ans = $self->ask(
      action => 'login',
      lgname => $self->{username},
      lgpassword => $args{password}
    );
    if ($ans->{login}{result} eq 'Success')
    {
      $self->{sessionid} = $ans->{login}{sessionid};
      $self->notice("you successfully logged in as $self->{username}");
    }
    elsif ($ans->{login}{result} eq 'NeedToken')
    {
      $ans = $self->ask(
	action => 'login',
	lgname => $self->{username},
	lgpassword => $args{password},
	lgtoken => $ans->{login}{token}
      );
      croak "Unable to log in with this (username,password) couple! (server ".
      "answered: `$ans->{login}{result}')"
	unless ($ans->{login}{result} eq 'Success');
      $self->{sessionid} = $ans->{login}{sessionid};
      $self->notice("you successfully logged in as $self->{username}");
    }
    else
    {
      croak "Unable to log in with this (username,password) couple! (server ".
      "answered: `$ans->{login}{result}')";
    }
  }
  else
  {
    $self->notice("recall the fact that you are not logged in: you may not ".
      "be able to access to certain API features");
    return $self;
  }

  # Get edit token.
  my $ans = $self->ask(
    action	=> 'query',
    prop	=> 'info',
    intoken	=> 'edit|delete|protect|move|block|unblock'
  );

  print Dump($ans);

  return $self;
}


# SEND A REQUEST TO THE API
# Expected parameters:
# each POST field must be passed as "key => value" rows, so the easiest
# way of calling ask() is probably with a hash.
# In addition to POST fields, you can set (or explicitely unset, if you
# want to) the `transmission_html_encode' option so that the characters
# are encoded with HTML::Entities; this is discouraged for login requests.
sub ask
{
  my ($self, %args) = @_;

  if ($args{transmission_html_encode})
  {
    delete $args{transmission_html_encode};
    %args = map({ encode_entities $_ } %args);
  }
  $args{format} = 'yaml';

  my $answer;
  my $attempts = 0;
  while ($attempts < $self->{tolerance})
  {
    $answer = $self->{ua}->post(
      $self->{url},
      Content_Type => 'application/x-www-form-urlencoded',
      Content => \%args
    );
    if ($answer->is_success)
    {
      # Directly returns the YAML structure loaded into a Perl hash reference.
      (my $r = $answer->decoded_content(raise_error => 1)) =~
	s/\\\//\//g;
      eval { $r = Load($r); };
      if ($@)
      {
	carp "An error occurred while Load()ing the YAML into Perl: $@\nThe ".
	  "server answer was: ".$answer->decoded_content();
	return undef;
      }
      return $r;
    }
    else
    {
      $self->notice("warning: attempt ".(++$attempts)."/$self->{tolerance} ".
	"of ASK()ing your stuff failed so miserably! (".$answer->status_line.
	")");
    }
  }
  # None of the $self->{tolerance} attempts has terminated correctly.
  $self->notice("Error: I have not been able to properly transfer the ".
    "request or to receive the API server's answer. Returning UNDEF.");
  return undef;
}


sub notice
{
  my $self = shift;
  if (ref $self eq 'Hermes')
  {
    return unless ($self->{verbose});
    print STDERR "\t\033[36mHermes::notice:\033[0m ", @_, "\n";
  }
  else
  {
    print STDERR "\t\033[36mHermes::notice:\033[0m ", $self, @_, "\n";
  }
}

sub DESTROY
{
  my $self = shift;
  $self->ask(
    action => 'logout'
  );
  $self->notice("user $self->{username} logged out");
}

#
1;
