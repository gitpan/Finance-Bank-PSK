# $Id: Makefile.PL,v 1.1.1.1 2003/01/28 15:22:28 florian Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Finance::Bank::PSK',
    'VERSION_FROM'	=> 'lib/Finance/Bank/PSK.pm',
    'PREREQ_PM'		=> {
    	'WWW::Mechanize'      => 0.35,
	'HTML::TokeParser'    => 2.24,
	'Class::MethodMaker'  => 1.06,
    	},
    'dist'              => {
    	'COMPRESS'            => 'gzip --force --best'
        },
);
