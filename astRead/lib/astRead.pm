package astRead;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Moo;

use astGlobalsObj;
use astfileLocn;

=head1 NAME

astRead - The great new astRead!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use astRead;

    my $foo = astRead->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

=cut

my $ROOT                    ='root';             # %
my   $CHILD_NUM             ='childNum';         # @ note recursive childern
my   $DEPTH                 ='depth';            # $
my   $DATA                  ='data';             # %
my     $TYPE                ='type';             # $
my     $ID                  ='id';               # $  eg 0x4f3ad88
my     $REST                ='rest';             # %
my       $ORIGINAL          ='original';         # $
my       $DECL_VAR          ='varDecl';          # % obj
my     $REGION              ='region';           # %
my       $START             ='start';            # % todo obj
my       $END               ='end';             # % todo obj
my     $START_LOC           ='startLoc';         # % todo obj


my $PAYLOAD='payload';
my $LOCATION='location';

has filename => ( is => 'ro', );

sub process {
   my ($self) = @_;

   $self->{$ROOT} = { $DEPTH => 0, $CHILD_NUM => [] };
   my $parent = $self->{$ROOT};
   my @chain;
   my $lastDepth = 0;
   open( my $fh, "<", $self->{filename} );
   foreach my $line (<$fh>) {
      $line =~ m/^[^\w<]*(.*)/;
      my $depth    = $-[1];
      my $newChild = {
         $DEPTH => $depth,
         $DATA  => _getData( $parent->{$CHILD_NUM}, $1 ),
      };
      if ( $depth > $lastDepth ) {
         $lastDepth = $depth;
         push @chain, $parent;
         $parent = ${ $parent->{$CHILD_NUM} }[-1];
      }
      else {
         while ( $depth < $lastDepth ) {
            $lastDepth = $parent->{$DEPTH};
            $parent    = pop @chain;
         }
      }
      push @{ $parent->{$CHILD_NUM} }, $newChild;
   }
}

#Extract all global variables into an array
sub getGlobalsList {
   my $self = shift;
   my $root = $self->{$ROOT};

   my %result;
   push( my @queue, @{ $root->{$CHILD_NUM}[0]->{$CHILD_NUM} } );
   my $container;
   my $i;
   while ( my $item = shift @queue ) {
      if ( $item->{$DATA}->{$TYPE} =~ /VarDecl/ ) {
         my $curtId = $item->{$DATA}->{$ID};
         my $rootId = $curtId;
         my $payload=$item->{$DATA}->{$REST}->{$DECL_VAR};
         my $prevId = $payload->prevId();
         if ( defined($prevId) ){
            $rootId = $prevId;
         }
         $container=\@{$result{$rootId}};
         my $construct={
            $PAYLOAD=>$payload,
            $LOCATION=>$item->{$DATA}->{$START_LOC},
         };

         if($payload->is_extern()){
            push @$container,$construct;
         }
         else{
            unshift @$container, $construct;
         }
      }
   }
   return \%result;
}

#todo: extract all global variables into a list of arrays (one array per $FILE)
#todo: extract all local variables into a list of arrays (one array per function)

=head2 function2

=cut



sub printGlobal {
   my $self = shift;
   my $itemNum = shift;
   my $i=0;
   foreach my $item(@$itemNum)
   {
      if($i++ > 0){
         print (" "x5);
         print ("- ");
      }
      print "File:  <". $item->{$LOCATION}->get_file_for()
      . ">  Line:". $item->{$LOCATION}->get_line_for() . " | ";
      print $item->{$PAYLOAD}->$GET_IS_USED_STRING($item). " | ";
      print $item->{$PAYLOAD}->$VAR_NAME. " | ";
      print $item->{$PAYLOAD}->$UNDERLYING_TYPE. " | ";
      print $item->{$PAYLOAD}->$VAR_TYPE. " | ";
      print "--CONST-- | " if $item->{$PAYLOAD}->$IS_CONST;
      print "\n";
   }
}


sub printTree {
   my $self = shift;
   my $root = $self->{$ROOT};
   push( my @queue, @{ $root->{$CHILD_NUM} } );
   while ( my $item = shift @queue ) {
      print(
             " " x $item->{$DEPTH}
           . $item->{$DATA}->{$TYPE} . ", "
           . $item->{$DATA}->{$ID} . ", " . "<<"
           . (
                $item->{$DATA}->{$REGION}->{$START}->printableLoc()
           )
           . ">" . "<"
           . (
                $item->{$DATA}->{$REGION}->{$END}->printableLoc()
           )
           . ">>" . "["
           . (
                $item->{$DATA}->{$START_LOC}->printableLoc()
           )
           . "]"
           . $item->{$DATA}->{$REST}->{$ORIGINAL} . "\n"
      );
      if ( exists $item->{$CHILD_NUM} ) {
         unshift @queue, @{ $item->{$CHILD_NUM} };
      }
   }
}

sub _getData {
   my ( $refSibblingNum, $in ) = @_;
   $in =~ m/
      ^[^\w<]*<*([\w]*)\s*>*       #$1 $type
      \s*(\S*)                     #$2 $id
      \s*(?:prev\s*(\S*))?         #$3 $prevId
      [^<]*<*([^>]*)>*             #$4 $rawRegion
      \s*(.*\S*)                   #$5 $rest
   /x;
   my ( $type, $id, $prevId, $rawRegion, $rawRest ) = ( $1, $2, $3, $4, $5 );
   $rawRest =~ m/
   \s*((?:line|col)(?::\d*\s*)*)?  #$1 $possibleStart
      \s*(.*\S*)                   #$2 $rest
   /x;
   my ( $possibleStart, $rest ) = ( $1, $2 );

   my $emptyLoc = astfileLocn->newEmptyLoc();
   my $prevLoc = { $START => $emptyLoc, $END => $emptyLoc };
   if ( @$refSibblingNum && exists $refSibblingNum->[-1]->{$DATA}->{$REGION} ) {
      $prevLoc = $refSibblingNum->[-1]->{$DATA}->{$REGION};
   }
   my $region = _getNewTimeRegion( $prevLoc, $rawRegion );
   my $startLoc = astfileLocn->determineLocFrom( $region->{$START}, $possibleStart );

   my %globVar;
   my %body;
   if ( $type =~ /VarDecl/ ) {
      $body{$DECL_VAR} =  astGlobalsObj::getVarDecl( $rest, $id, $prevId );
   }
   $body{$ORIGINAL} = $rest;
   return {
      $TYPE      => $type,
      $ID        => $id,
      $REST      => \%body,
      $REGION    => $region,
      $START_LOC => $startLoc,
   };
}


sub _getNewTimeRegion {
   my ( $lastLoc, $rawRegion ) = @_;
   my $loc = { $START => {}, $END => {} };
   if ( $rawRegion =~ m/:/ ) {
      my ( $start, $end ) = split( /,/, $rawRegion );
      $loc->{$START} = astfileLocn->determineLocFrom( $lastLoc->{$END}, $start );
      if ( defined $end ) {
         $loc->{$END} = astfileLocn->determineLocFrom( $loc->{$START}, $end );
      }
      else {
         $loc->{$END} = $loc->{$START};
      }
   }
   else {
      $loc = $lastLoc;
   }
   return $loc;
}


=head1 AUTHOR

Bryan Jarmain, C<< <bjarmain@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-astread at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=astRead>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc astRead


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=astRead>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/astRead>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/astRead>

=item * Search CPAN

L<http://search.cpan.org/dist/astRead/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Bryan Jarmain.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of astRead
