package astRead;

use 5.006;
use strict;
use warnings FATAL => 'all';

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
#%root
#  $depth
#  \@childNum
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
#     \%startLoc
#        $file
#        $line
#        $col
#

=cut

sub new {
   my ( $context, $filename ) = @_;

   my %root = ( depth => 0, childNum => [] );
   my $parent = \%root;
   my @chain;
   my $lastDepth = 0;
   open( my $fh, "<", $filename );
   foreach my $line (<$fh>) {
      $line =~ m/^[^\w<]*(.*)/;
      my $depth    = $-[1];
      my $newChild = {
         depth => $depth,
         data  => getData( $parent->{childNum}, $1 ),
      };
      if ( $depth > $lastDepth ) {
         $lastDepth = $depth;
         push @chain, $parent;
         $parent = ${ $parent->{childNum} }[-1];
      }
      else {
         while ( $depth < $lastDepth ) {
            $lastDepth = $parent->{depth};
            $parent = pop @chain;
         }
      }
      push @{ $parent->{childNum} }, $newChild;
   }
   bless \%root, $context;
}

sub getData {
   my ( $lastLine, $in ) = @_;
   $in =~ m/
      ^[^\w<]*<*([\w]*)\s*>*       #$1 $type
      \s*(\S*)                     #$2 $id
      [^<]*<*([^>]*)>*             #$3 $rawRegion
      \s*(.*\S*)                   #$4 $rest
   /x;
   my ( $type, $id, $rawRegion, $rawRest ) = ( $1, $2, $3, $4 );
   $rawRest =~ m/
   \s*((?:line|col)(?::\d*\s*)*)?  #$1 $possibleStart
      \s*(.*\S*)                   #$2 $rest
   /x;
   my ( $possibleStart, $rest ) = ( $1, $2 );

   my %emptyLoc = ( file => "na", line => "na", col => "na" );
   my $prevLoc = { start => \%emptyLoc, end => \%emptyLoc };
   if ( @$lastLine && exists $lastLine->[-1]->{data}->{region} ) {
      $prevLoc = $lastLine->[-1]->{data}->{region};
   }
   my $region = getNewTimeRegion( $prevLoc, $rawRegion );
   my $startLoc = determineLocFrom( $region->{start}, $possibleStart );
   return {
      type     => $type,
      id       => $id,
      region   => $region,
      startLoc => $startLoc,
      rest     => $rest,
   };
}

sub getNewTimeRegion {
   my ( $lastLoc, $rawRegion ) = @_;
   my $loc = { start => {}, end => {} };
   if ( $rawRegion =~ m/:/ ) {
      my ( $start, $end ) = split( /,/, $rawRegion );
      $loc->{start} = determineLocFrom( $lastLoc->{end}, $start );
      if ( defined $end ) {
         $loc->{end} = determineLocFrom( $loc->{start}, $end );
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
   my ( $lastLoc, $raw ) = @_;
   my %loc = ();
   %loc = %$lastLoc if defined $lastLoc;
   my ( $a, $b, $c );
   ( $a, $b, $c ) = split( /:/, $raw ) if defined $raw;
   if ( defined $a ) {
      if ( defined $c ) {
         $loc{col} = $c;
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
   }
   $loc{file}=rationalizePath($loc{file});
   return \%loc;
}
use File::Spec;

sub rationalizePath{
   my $pathToRationalize=shift;
   $pathToRationalize =~ s/\\/\//g;
   $pathToRationalize = File::Spec->canonpath($pathToRationalize);
   my ($volume,$directories,$file) = File::Spec->splitpath( $pathToRationalize );
   my @dirs=File::Spec->splitdir($directories);
   my @newDirs;
   foreach my $dirSeg(@dirs){
      if($dirSeg eq '..' && @newDirs &&  $newDirs[-1] ne '..'){
         pop @newDirs;
      }
      else{
         push @newDirs,$dirSeg;
      }
   }
   $directories=File::Spec->catdir(@newDirs);
   $pathToRationalize=File::Spec->catpath($volume,$directories,$file);
   return $pathToRationalize;

}


#todo: extract all global variables into an array
#todo: extract all global variables into a list of arrays (one array per file)
#todo: extract all local variables into a list of arrays (one array per function)

=head2 function2

=cut

sub printTree {
   my $self = shift;
   my $root = $self;
   push( my @queue, @{ $root->{childNum} } );
   while ( my $item = shift @queue ) {
      print(
             " " x $item->{depth}
           . $item->{data}->{type} . ", "
           . $item->{data}->{id} . ", " . "<<"
           . (
                $item->{data}->{region}->{start}->{file} . ": "
              . $item->{data}->{region}->{start}->{line} . ": "
              . $item->{data}->{region}->{start}->{col}
           )
           . ">" . "<"
           . (
                $item->{data}->{region}->{end}->{file} . ": "
              . $item->{data}->{region}->{end}->{line} . ": "
              . $item->{data}->{region}->{end}->{col}
           )
           . ">>" . "["
           . (
                $item->{data}->{startLoc}->{file} . ": "
              . $item->{data}->{startLoc}->{line} . ": "
              . $item->{data}->{startLoc}->{col}
           )
           . "]"
           . $item->{data}->{rest} . "\n"
      );
      if ( exists $item->{childNum} ) {
         unshift @queue, @{ $item->{childNum} };
      }
   }
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
