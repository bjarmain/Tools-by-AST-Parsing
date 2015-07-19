package astGlobalsObj;

use strict;
use warnings;
use Moo;

use Exporter qw(import);
our @EXPORT = qw(getVarDecl $IS_CONST $VAR_NAME $UNDERLYING_TYPE $VAR_TYPE $GET_IS_USED_STRING);

our $VERSION = '0.01';

my         $IS_USED         ='is_used';          # $ BOOL
my         $IS_EXTERN       ='is_extern';        # $ BOOL
our        $IS_CONST        ='is_const';         # $ BOOL
our        $VAR_NAME        ='var_name';         # $
our        $UNDERLYING_TYPE ='underlying_type';  # $
our        $VAR_TYPE        ='varType';          # $
our        $GET_IS_USED_STRING='get_is_used_string';
my         $PREV_ID         ='prevId';           # $  eg 0x4f3ad88



has   $IS_USED         =>(is => 'ro',);
has   $VAR_NAME        =>(is => 'ro',);
has   $UNDERLYING_TYPE =>(is => 'ro',);
has   $VAR_TYPE        =>(is => 'ro',);
has   $PREV_ID         =>(is => 'ro',); #previously seen reference (eg an exern declaration)
has   $IS_EXTERN       =>(is => 'ro',);
has   $IS_CONST        =>(is => 'ro',);

sub getVarDecl {
   my ( $rest, $id, $prevId ) = @_;
   $rest =~ /
   \s*(used)?       #$IS_USED
   \s*(\w*)         #$VAR_NAME
   \s*'([^']*)'     #$UNDERLYING_TYPE
   \W*([^']*)       #$TYPE
   /x;
   my $underlying_type = $3;
   my $type = $4;
   my $isConst=($type eq "cinit")||($underlying_type=~/const/);
   my $varType=(defined $4 && (0 < length( $4 )))? $4:$underlying_type ;
   return astGlobalsObj->new(
      $IS_USED         =>$1,
      $VAR_NAME        =>$2,
      $UNDERLYING_TYPE =>$underlying_type,
      $VAR_TYPE        =>$varType,
      $PREV_ID         =>$prevId,
      $IS_EXTERN       =>$type eq "extern",
      $IS_CONST        =>$isConst,
   );
}

sub get_is_used_string{
   my ($self) = @_;
   return($self->{$IS_USED} // "UNUSED");
}



1;
