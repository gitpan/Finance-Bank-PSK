# $Id: PSK.pm,v 1.4 2003/06/20 21:16:07 florian Exp $

package Finance::Bank::PSK;

require 5.005_62;
use strict;
use warnings;

use Carp;
use WWW::Mechanize;
use HTML::TokeParser;
use Class::MethodMaker
  new_hash_init => 'new',
  get_set       => [ qw/ account user pass / ],
  boolean       => 'return_floats';

our $VERSION = '0.02';


sub check_balance {
	my $self  = shift;
	my $agent = WWW::Mechanize->new;

	croak "Need account number to connect.\n" unless $self->account;
	croak "Need user to connect.\n" unless $self->user;
	croak "Need password to connect.\n" unless $self->pass;

	$agent->get('https://wwwtb.psk.at/InternetBanking/sofabanking.html');
	$agent->follow(0);
	$agent->form(1);
	$agent->field('tn', $self->account);
	$agent->field('vf', $self->user);
	$agent->field('pin', $self->pass);
	$agent->click('Submit');

	# XXX write tests using the demo account!
	#$agent->follow('Demo');

	$self->_parse_summary($agent->content);
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
