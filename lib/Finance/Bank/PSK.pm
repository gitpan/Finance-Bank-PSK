# $Id: PSK.pm,v 1.3 2003/01/29 22:02:44 florian Exp $

package Finance::Bank::PSK;

require 5.005_62;
use strict;
use warnings;

use Data::Dumper;
use WWW::Mechanize;
use HTML::TokeParser;
use Class::MethodMaker
  new_hash_init => 'new',
  get_set       => [ qw/ account user pass / ],
  boolean       => 'return_floats';

our $VERSION = '0.01';


sub check_balance {
	my $self  = shift;
	my $agent = WWW::Mechanize->new;

	die "Need account number to connect.\n" unless $self->account;
	die "Need user to connect.\n" unless $self->user;
	die "Need password to connect.\n" unless $self->pass;

	$agent->get('https://wwwtb.psk.at/InternetBanking/sofabanking.html');
	$agent->follow(0);
	$agent->form(1);
	$agent->field('tn', $self->account);
	$agent->field('vf', $self->user);
	$agent->field('pin', $self->pass);
	$agent->click('Submit');

	# XXX write tests using the demo account!
	#$agent->follow('Demo');

	$self->_parse_summary($agent->{content});
}


sub _parse_summary {
	my($self, $content) = @_;
	my $stream = HTML::TokeParser->new(\$content);
	my %result;

	# get every interesting 'subtitle'.
	while($stream->get_tag('span')) {
		my %data;
		my $type = $stream->get_trimmed_text('/span');

		# catch girokontos.
		if($type eq 'Girokonto') {
			my $tmp;

			# get name, number and currency of the account.
			$stream->get_tag('a');
			$tmp = $stream->get_text('/a');
			(undef, $data{name}, undef, $tmp) = split(/\n/, $tmp);
			($data{account}, $data{currency}) = split(/\//, $tmp);

			$data{account} = $self->_cleanup($data{account});
			$data{name} = $self->_cleanup($data{name});

			# get the balance and the final balance of the account.
			for(qw/balance final/) {
				$stream->get_tag('table');
				$stream->get_tag('td') for 1 .. 2;

				$data{$_} = $stream->get_trimmed_text('/td');
				$data{$_} = $self->_scalar2float($data{$_}) if $self->return_floats;
			}

			push @{$result{accounts}}, \%data;
		# catch wertpapierdepots
		} elsif($type eq 'Wertpapierdepot') {
			# get name and number of the fund.
			$stream->get_tag('a');
			(undef, $data{name}, undef, $data{fund}) = split(/\n/, $stream->get_text('/a'));

			$data{fund} = $self->_cleanup($data{fund});
			$data{name} = $self->_cleanup($data{name});

			# get the balance of the fund.
			$stream->get_tag('table');
			$stream->get_tag('td');
			$data{currency} = $stream->get_trimmed_text('/td');

			$stream->get_tag('td');
			$data{balance} = $stream->get_trimmed_text('/td');
			$data{balance} = $self->_scalar2float($data{balance}) if $self->return_floats;

			push @{$result{funds}}, \%data;
		}

	}

	\%result;
}


sub _scalar2float {
	my($self, $scalar) = @_;

	$scalar =~ s/\.//g;
	$scalar =~ s/,/\./g;

	return $scalar;
}


sub _cleanup {
	my($self, $string) = @_;

	$string =~ s/^\s+//g;
	$string;
}


1;
__END__

=head1 NAME

Finance::Bank::PSK - check your P.S.K. accounts from Perl

=head1 SYNOPSIS

  # look for this script in the examples directory of the
  # tar ball.
  use Finance::Bank::PSK;
  
  use strict;
  use warnings;
  
  my $agent = Finance::Bank::PSK->new(
	  account       => 'xxx',
          user          => 'xxx',
          pass          => 'xxx',
          return_floats => 1,
  );
  
  my $result = $agent->check_balance;
  
  foreach my $account (@{$result->{accounts}}) {
          printf("%11s: %25s\n", $_->[0], $account->{$_->[1]})
                  for(( [ qw/ Kontonummer account / ],
                        [ qw/ Bezeichnung name / ],
                        [ qw/ Waehrung currency / ]
                  ));
          printf("%11s: %25.2f\n", $_->[0], $account->{$_->[1]})
                  for(( [ qw/ Saldo balance / ],
                        [ qw/ Dispo final / ]
                  ));
          print "\n";
  }
  
  foreach my $fund (@{$result->{funds}}) {
          printf("%11s: %25s\n", $_->[0], $fund->{$_->[1]})
                  for(( [ qw/ Depotnummer fund / ],
                        [ qw/ Bezeichnung name / ],
                        [ qw/ Waehrung currency / ]
                  ));
          printf("%11s: %25.2f\n", 'Saldo', $fund->{balance});
          print "\n";
  }

=head1 DESCRIPTION

This module provides a basic interface to the online banking system of
the P.S.K. at C<https://wwwtb.psk.at>.

Please note, that you will need either C<Crypt::SSLeay> or C<IO::Socket::SSL>
installed for working HTTPS support of C<LWP>.

=head1 METHODS

=over

=item check_balance

Queries the via user and pass defined accounts and mutual funds and
returns a reference to a list of hashes containing all fetched
information:

  $VAR1 = {
            'accounts' => [
                            {
                              'name'     => name of the account
                              'account'  => account number
                              'currency' => currency
                              'balance'  => account balance
                              'final'    => final account balance
                          ]
            'funds' => [
                          {
                            'name'     => name of the mutual fund
                            'fund'     => mutual fund number
                            'currency' => currency
                            'balance'  => mutual fund balance
                          }
                        ]
          };

=back

=head1 ATTRIBUTES

All attributes are implemented by C<Class::MethodMaker>, so please take a
look at its man page for further information about the created accessor
methods.

=over

=item account

Account to connect with (Teilnehmernummer).

=item user

User to connect with (Verfueger).

=item pass

Password to connect with (PIN).

=item return_floats

Boolean value defining wether the module returns the balance as signed
float or just as it gets it from the online banking system (default:
false).

=back

=head2 WARNING

This is code for B<online banking>, and that means B<your money>, and that
means B<BE CAREFUL>. You are encouraged, nay, expected, to audit the source 
of this module yourself to reassure yourself that I am not doing anything 
untoward with your banking data. This software is useful to me, but is 
provided under B<NO GUARANTEE>, explicit or implied.

=head1 THANKS

Simon Cozens <simon@cpan.org> for C<Finance::Bank::LloydsTSB> from which I've
borrowed the warning message.

Chris Ball <chris@cpan.org> for his article about screen-scraping with
C<WWW::Mechanize> at C<http://www.perl.com/pub/a/2003/01/22/mechanize.html>.

=head1 AUTHOR

Florian Helmberger <fh@laudatio.com>

=head1 VERSION

$Id: PSK.pm,v 1.3 2003/01/29 22:02:44 florian Exp $

=head1 COPYRIGHT AND LICENCE

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

Copyright (C) 2003 Florian Helmberger

=head1 SEE ALSO

L<WWW::Mechanize>, L<HTML::TokeParser>, L<Class::MethodMaker>.

=cut
