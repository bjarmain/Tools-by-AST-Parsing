package astGlobalsObj;

use strict;
use warnings;
use Moo;
use 5.010;

use Exporter qw(import);
our @EXPORT = qw(getVarDecl $IS_CONST $VAR_NAME $UNDERLYING_TYPE $VAR_TYPE);

our $VERSION = '0.01';

my $IS_USED   = 'is_used';      # $ BOOL
my $IS_EXTERN = 'is_extern';    # $ BOOL
our $IS_CONST        = 'is_const';           # $ BOOL
our $VAR_NAME        = 'var_name';           # $
our $UNDERLYING_TYPE = 'underlying_type';    # $
our $VAR_TYPE        = 'varType';            # $
my $PREV_ID = 'prevId';                      # $  eg 0x4f3ad88

has $IS_USED         => ( is => 'ro', );
has $VAR_NAME        => ( is => 'ro', );
has $UNDERLYING_TYPE => ( is => 'ro', );
has $VAR_TYPE        => ( is => 'ro', );
has $PREV_ID         => ( is => 'ro', )
  ;    #previously seen reference (eg an exern declaration)
has $IS_EXTERN => ( is => 'ro', );
has $IS_CONST  => ( is => 'ro', );

sub getVarDecl {
   my ( $rest, $id, $prevId ) = @_;
   $rest =~ /
   \s*(used)?       #$IS_USED
   \s*(\w*)         #$VAR_NAME
   \s*'([^']*)'     #$UNDERLYING_TYPE
   \W*([^']*)       #$TYPE
   /x;
   my $underlying_type = $3;
   my $type            = $4;
   my $isConst = ( $type eq "cinit" ) || ( $underlying_type =~ /const/ );
   my $varType = ( defined $4 && ( 0 < length($4) ) ) ? $4 : $underlying_type;
   return astGlobalsObj->new(
      $IS_USED         => $1,
      $VAR_NAME        => $2,
      $UNDERLYING_TYPE => $underlying_type,
      $VAR_TYPE        => $varType,
      $PREV_ID         => $prevId,
      $IS_EXTERN       => $type eq "extern",
      $IS_CONST        => $isConst,
   );
}

sub get_is_used_string {
   my ($self) = @_;
   return ( $self->{$IS_USED} // "UNUSED" );
}

sub print_global_description {
   my $self = shift;
   my $res =
       $self->get_is_used_string() . " | "
     . $self->$VAR_NAME . " | "
     . $self->$UNDERLYING_TYPE . " | "
     . $self->$VAR_TYPE . " | ";
   $res .= "--CONST-- | " if $self->$IS_CONST;
   $res;
}

sub getAnyNamingConventionError {
   my $self = shift;
   my ( $namespaceKey, $isHeader ) = @_;
   my ( $isError, $res ) = ( 0, "" );
   my $isStatic = $self->$UNDERLYING_TYPE =~ /static/i;

   if ( $self->$IS_CONST ) {
      $namespaceKey = "CONST_IN_$namespaceKey";
   }

   if ($isHeader) {
      ( $isError, $res ) =
        headerFileGetAnyNamingConventionError( $self, $isStatic, $namespaceKey,
         $isError, $res );
   }
   else {
      ( $isError, $res ) =
        sourceFileGetAnyNamingConventionError( $self, $isStatic, $namespaceKey,
         $isError, $res );
   }

   ( $isError, $res ) =
     anyFileGetAnyNamingConventionError( $self, $isStatic, $namespaceKey,
      $isError, $res );

   $res = "(" . $self->$VAR_NAME . ") $res";
   if ( !$isError ) {
      $self->{lastGoodVarNameFor}->{$namespaceKey} = $self->$VAR_NAME;
   }
   return ( $isError, $res );
}

sub anyFileGetAnyNamingConventionError {
   my ( $self, $isStatic, $namespaceKey, $isError, $res ) = @_;
   if ( !$isError && $self->$IS_CONST && $self->$VAR_NAME =~ /[a-z]/ ) {
      ( $isError, $res ) =
        ( 1, "constant variable needs to be all upper case" );
   }

   if ( !$isError && !$self->$IS_CONST && $self->$VAR_NAME =~ /^[A-Z_]/ ) {
      ( $isError, $res ) =
        ( 1, "variable must start with a small letter namespace" );
   }
   return ( $isError, $res );
}

sub sourceFileGetAnyNamingConventionError {
   my ( $self, $isStatic, $namespaceKey, $isError, $res ) = @_;
   if ( !$isError && !$isStatic ) {
      ( $isError, $res ) =
        ( 1, "variable declared in source file should be static" );
   }
   return ( $isError, $res );
}

sub headerFileGetAnyNamingConventionError {
   my ( $self, $isStatic, $namespaceKey, $isError, $res ) = @_;
   if ( !$isError && $isStatic ) {
      ( $isError, $res ) = ( 1, "static Variable Cannot be in a Header File" );
   }

   if ( !$isError && !$self->$IS_CONST && $self->$VAR_NAME !~ /_/ ) {
      ( $isError, $res ) = (
         1, "Variable needs a namespace separated from the name with an \"_\""
      );
   }

   if ( !$isError && $self->$VAR_NAME =~ /^[^_]*[us]\d/i ) {
      ( $isError, $res ) = ( 1, "Variable should not use hungarian notation" );
   }

   if ( !$isError ) {
      my $lastGoodName = $self->{lastGoodVarNameFor}->{$namespaceKey};
      if ( defined $lastGoodName
         && $lastGoodName =~ /^([^_]*)/ )
      {
         my $lastGoodNamespace = $1;
         if ( !defined($1) ) {
            ( $isError, $res ) =
              ( 1, "variable name needs to start with a namespace" );
         }
         else {
            if ( $self->$VAR_NAME !~ /^$lastGoodNamespace/ ) {
               ( $isError, $res ) = (
                  1, "variable name needs to start with a consistant namespace"
               );
            }
         }
      }
   }
   return ( $isError, $res );
}

1;
