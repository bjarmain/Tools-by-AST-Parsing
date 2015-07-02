#!/bin/usr/perl
use strict;
use warnings;
use 5.018;
use lib "lib";

use astRead;

my $ast=astRead->new($ARGV[0]);
#$ast->printTree();

my $globalsRef=$ast->getGlobalsList();

my $iterator;
for my $myGlobal(@$globalsRef){
   print ++$iterator . ': ';
   $ast->printItem($myGlobal);
}