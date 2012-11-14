package Power::Search;

use strict;
use warnings;
use 5.010;

our $VERSION = 1.0;

use Carp;
use re::engine::RE2 0.11;

use Core::Hermes 1.0;


# utiliser srwhat=text
# action=query&list=search&srsearch=bateau&srwhat=text&format=xml&srlimit=500


1;
__END__

=head1 NAME

Power::Search - Search through the wiki.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module defines a standard for performing efficient searches through
MediaWiki.

=head1 AUTHOR

thilp <thilp.is@gmail.com>

=head1 LICENSE AND COPYRIGHT

All this code is released under the GNU Public License, version 3.

See http://www.gnu.org/licenses/gpl.html for details.
