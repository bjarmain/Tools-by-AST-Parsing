#!/usr/bin/perl
use 5.018;
use strict;
use warnings;

#%root
#  $depth
#  \%data
#     $type
#     $id
#     $rest
#     \%region
#        \%start
#           $file
#           $line
#           $col
#        \%end
#           $file
#           $line
#           $col

my $cnt = 0;
my @fileFor;
my @lineFor;
my %root = ( depth => 0, childNum => [] );
my $parent = \%root;

open( my $fh, "<", $ARGV[0] );
foreach my $line (<$fh>) {
   $line =~ m/(\w.*)/;
   my $depth    = $-[1];
   my $newChild = {
      parent => $parent,
      depth  => $depth,
      data   => getData( $parent->{childNum}, $1 ),
   };
   if ( $depth > $parent->{depth} ) {
      $parent = ${ $parent->{childNum} }[-1];
   }
   else {
      while ( $depth < $parent->{depth} ) {
         $parent = $parent->{parent};
      }
   }
   push @{ $parent->{childNum} }, $newChild;
}

push( my @queue, @{ $root{childNum} } );
while ( my $item = shift @queue ) {
   print(
          " " x $item->{depth}
        . $item->{data}->{type} . ", "
        . $item->{data}->{id}   . ", "
        . (
             $item->{data}->{region}->{start}->{file} . ": "
           . $item->{data}->{region}->{start}->{line} . ": "
           . $item->{data}->{region}->{start}->{col} . ", "
        )
        . (
             $item->{data}->{region}->{end}->{file} . ": "
           . $item->{data}->{region}->{end}->{line} . ": "
           . $item->{data}->{region}->{end}->{col}
        )
        . "\n"
   );
   if ( exists $item->{childNum} ) {
      unshift @queue, @{ $item->{childNum} };
   }
}
say "done-------------------------------------";

sub getData {
   my ( $lastLine, $in ) = @_;
   $in =~ m/
      ^\W*(\w*)         #$1 type
      \s*(\S*)          #$2 id
      [^<]*<*([^>]*)>*  #$3 rawLoc
      \s*(.*\S*)        #$4 rest
   /x;
   my %emptyLoc=(file=>"na", line=>"na", col=>"na");
   my $prevLoc = {start=>\%emptyLoc, end=>\%emptyLoc};
   if ( @$lastLine && exists $lastLine->[-1]->{data}->{region} ) {
      $prevLoc = $lastLine->[-1]->{data}->{region};
   }
   my $rawLoc = $3;
   return {
      type    => $1,
      id      => $2,
      region => getNewLoc( $prevLoc, $rawLoc ),
      rest    => $4
   };
}

sub getNewLoc {
   my ( $lastLoc, $rawLoc ) = @_;
   my $loc = { start => {}, end => {} };
   if ( $rawLoc =~ m/:/ ) {
      my ( $start, $end ) = split( /,/, $rawLoc );
      $loc->{start} = determineLocFrom( $start, $lastLoc->{end} );
      if ( defined $end ) {
         $loc->{end} = determineLocFrom( $end, $loc->{start} );
      }
      else {
         $loc->{end} = $loc->{start};
      }
   }
   else {
      $loc = $lastLoc;
   }
   return $loc;
}

sub determineLocFrom {
   my ( $raw, $lastLoc ) = @_;
   my %loc = ();
   %loc = %$lastLoc if defined $lastLoc;
   my ( $a, $b, $c ) = split( /:/, $raw );

   if ( defined $c ) {
      $loc{col} = $b;
   }

   if ( $a !~ m/\A\s*(line|col)\s*\Z/i ) {
      $loc{file} = $a;
      $loc{line} = $b if defined $b;
   }

   if ( $a =~ m/\A(line)\Z/i ) {
      $loc{line} = $b;
   }

   if ( $a =~ m/\A\s*(col)\s*\Z/i ) {
      $loc{col} = $b;
   }
   return \%loc;
}
