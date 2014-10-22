=head1 NAME

Bio::Polloc::Genome - A group of sequences from the same organism

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Polloc::Root>

=back

=cut

package Bio::Polloc::Genome;
use strict;
use base qw(Bio::Polloc::Polloc::Root);
use Bio::SeqIO;
our $VERSION = 1.0502; # [a-version] from Bio::Polloc::Polloc::Version


=head1 PUBLIC METHODS

Methods provided by the package

=head2 new

The basic initialization method

B<Arguments>

=over

=item -name I<str>

The name of the genome (from file if not provided).

=item -file I<str>

The file containing the (multi-)fasta with the genome.

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 file

Sets/gets the file containing the genome

=cut

sub file {
   my($self, $value) = @_;
   if(defined $value){
      $self->{'_file'} = $value;
      $self->{'_sequences'} = undef;
   }
   return $self->{'_file'};
}

=head2 get_sequences

Gets the collection of sequences.

B<Returns>

An array of L<Bio::Seq> objects.

=cut

sub get_sequences {
   my $self = shift;
   return $self->{'_sequences'} if defined $self->{'_sequences'};
   $self->{'_sequences'} = [];
   my $seqIO = Bio::SeqIO->new(-file=>$self->file, -format=>'Fasta');
   while(my $seq = $seqIO->next_seq){
      push @{ $self->{'_sequences'} }, $seq;
   }
   return wantarray ? @{$self->{'_sequences'}} : $self->{'_sequences'};
}

=head2 search_sequence

Search a sequence by ID

B<Arguments>

The id (I<str>) of the sequence.

B<Returns>

The sequence (L<Bio::Seq>) or C<undef>.

=cut

sub search_sequence {
   my($self, $value) = @_;
   return unless defined $value;
   for my $seq (@{$self->get_sequences}){
      (my $sid = $seq->display_id) =~ s/^(?:[^\s]*\|)?([^\s^\|]+?)\|?$/$1/;
      return $seq if $seq->display_id eq $value or $sid eq $value;
   }
   return;
}

=head2 name

Gets/sets the name of the genome.  If no name is set,
tries to use the file instead.

=cut

sub name {
   my ($self, $value) = @_;
   $self->{'_name'} = $value if defined $value;
   unless(defined $self->{'_name'}){
      my $f = $self->file;
      return unless defined $f;
      $f =~ s/.*\///;
      $f =~ s/\.[^\.]+$//;
      $self->{'_name'} = $f;
   }
   return $self->{'_name'};
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my ($self, @args) = @_;
   my($name, $file) = $self->_rearrange([qw(NAME FILE)], @args);
   $self->name($name);
   $self->file($file);
}

1;
