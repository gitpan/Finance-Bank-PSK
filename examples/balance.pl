#!/usr/bin/perl

# $Id: balance.pl,v 1.3 2003/01/29 22:02:42 florian Exp $

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
