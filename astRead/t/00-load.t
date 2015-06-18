#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'astRead' ) || print "Bail out!\n";
}

diag( "Testing astRead $astRead::VERSION, Perl $], $^X" );
