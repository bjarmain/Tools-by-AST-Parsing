package astfileLocn;

use 5.006;
use strict;
use warnings FATAL => 'all';

use File::Spec;
use Moo;

use Exporter qw(import);
our @EXPORT = qw(determineLocFrom );


=head1 NAME

astfileLocn - The great new astfileLocn!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use astfileLocn;

    my $foo = astfileLocn->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS
=cut

my         $FILE            ='file';             # $
my         $LINE            ='line';             # $
my         $COL             ='col';              # $


sub determineLocFrom {
   my ($object, $lastLoc, $raw ) = @_;
   my %loc = ();
   %loc = %$lastLoc if defined $lastLoc;
   my ( $a, $b, $c );
   ( $a, $b, $c ) = split( /:/, $raw ) if defined $raw;
   if ( defined $a ) {
      if ( defined $c ) {
         $loc{$COL} = $c;
      }

      if ( $a !~ m/\A\s*(line|col)\s*\Z/i ) {
         $loc{$FILE} = $a;
         $loc{$LINE} = $b if defined $b;
      }

      if ( $a =~ m/\A(line)\Z/i ) {
         $loc{$LINE} = $b;
      }

      if ( $a =~ m/\A\s*(col)\s*\Z/i ) {
         $loc{$COL} = $b;
      }
   }
   $loc{$FILE} = _rationalizePath( $loc{$FILE} );
   bless \%loc,$object;
}

sub _rationalizePath {
   my $pathToRationalize = shift;
   $pathToRationalize =~ s/\\/\//g;
   $pathToRationalize = File::Spec->canonpath($pathToRationalize);
   my ( $volume, $directories, $file ) =
     File::Spec->splitpath($pathToRationalize);
   my @dirs = File::Spec->splitdir($directories);
   my @newDirs;
   foreach my $dirSeg (@dirs) {
      if ( $dirSeg eq '..' && @newDirs && $newDirs[-1] ne '..' ) {
         pop @newDirs;
      }
      else {
         push @newDirs, $dirSeg;
      }
   }
   $directories = File::Spec->catdir(@newDirs);
   $pathToRationalize = File::Spec->catpath( $volume, $directories, $file );
   return $pathToRationalize;
}

sub newEmptyLoc{
   bless{ $FILE => "na", $LINE => "na", $COL => "na" },shift;
}

sub get_file_for{
   my ($self) = @_;
   return($self->{$FILE});
}

sub get_line_for{
   my ($self) = @_;
   return($self->{$LINE});
}


sub printableLoc{
   my $self=shift;
     $self->{$FILE} . ": "
   . $self->{$LINE} . ": "
   . $self->{$COL}
}



=head1 AUTHOR

Bryan Jarmain, C<< <'bjarmain at gmail.com'> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc astfileLocn


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/.>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/.>

=item * Search CPAN

L<http://search.cpan.org/dist/./>

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

1; # End of astfileLocn
