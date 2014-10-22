#!/usr/bin/perl

use strict;
use Bio::Polloc::LocusIO 1.5010;
use Bio::Polloc::Genome;
use Bio::Polloc::LociGroup;
use Bio::Polloc::TypingI;

sub usage($);

# ------------------------------------------------- INPUT
my $gff_in =  shift @ARGV;
my $groups =  shift @ARGV;
my $out    =  shift @ARGV;
my $draw   =  shift @ARGV;
my $cons   = (shift @ARGV || 100)+0;
my $len    = (shift @ARGV || 20)+0;
my $error  = (shift @ARGV || 0)+0;
my @names  = split /:/, shift @ARGV;
my @inseqs = @ARGV;

&usage('') unless $gff_in and $groups and $out and $#inseqs > -1;
Bio::Polloc::Polloc::Root->DEBUGLOG(-file=>">$out.log");
$Bio::Polloc::Polloc::Root::VERBOSITY = 4;

# ------------------------------------------------- READ INPUT
my $genomes = [];
for my $G (0 .. $#inseqs){
   push @$genomes, Bio::Polloc::Genome->new(-file=>$inseqs[$G], -name=>$names[$G], -id=>$G) }
my $LocusIO = Bio::Polloc::LocusIO->new(-file=>$gff_in);
my $inloci = $LocusIO->read_loci(-genomes=>$genomes);

# ------------------------------------------------- REFORM GROUPS
my @gr = ();
open GLIST, "<", $groups or die "I can not read '$groups': $!\n";
while(my $ln=<GLIST>){
   chomp $ln;
   my $lgroup = Bio::Polloc::LociGroup->new(-genomes=>$genomes);
   for my $lid (split /\s+/, $ln){
      $lgroup->add_locus($inloci->locus($lid)) if $lid !~ /^\s*$/;
   }
   push @gr, $lgroup;
}
close GLIST;

# ------------------------------------------------- TYPING
my $typing = Bio::Polloc::TypingI->new(
	-type=>'bandingPattern::amplification',
	-primerSize=>$len,
	-primerConservation=>($cons/100),
	-maxSize=>2000);
# Alternatively, this can be set with (but remember to use Bio::Polloc::TypingIO): 
# my $typing = Bio::Polloc::TypingIO->new(-file=>'t/vntrs.bme');

GROUP: for my $lgroupId (0 .. $#gr){
   my $lgroup = $gr[$lgroupId];
   $typing->locigroup($lgroup);
   my $ampl_loci = $typing->scan;
   my $loci_out = Bio::Polloc::LocusIO->new(-file=>">$out.amplif.$lgroupId.gff");
   $loci_out->write_locus($_) for @{$ampl_loci->loci};
   if($#{$ampl_loci->loci}>-1 and $draw){
      open IMG, ">", "$out.amplif.$lgroupId.png" or die "I can not open '$out.amplif.$lgroupId.png': $!\n";
      binmode IMG;
      print IMG $typing->graph->png;
      close IMG;
   }
}

# ------------------------------------------------- SUBROUTINES
sub usage($) {
   my $m = shift;
   print "$m\n" if $m;
   print <<HELP

   polloc_primers.pl - Designs primers to amplify the groups of loci
   in the given genomes and attempts to runs an in silico PCR.

   Usage: $0 [Params]
   Params, in that order:
      gff (path):	GFF3 file containing the loci to amplify.
      			Example: /tmp/polloc-vntrs.out.gff
      groups (path):	File containing the IDs of the grouped loci.
      			One line per group, and the IDs separated by
			spaces.
			Example: /tmp/polloc-vntrs.out.groups
      out (path):	Path to the base of the output files.
      			Example: /tmp/polloc-primers.out
      draw (str):	Should I produce graphical output?
      			Possible values: 'on' and '' (empty string).
      cons (float):	Consensus percentage for primers design.
			Default: 100
      len (int):	Length of the primers.
			Default: 20
      error (float):	Number of allowed mismatches during in silico
      			amplification.
			Default: 0
      names (str):	The names of the genomes separated by colons (:).
      			Alternatively, can be an empty string ('') to
			assign genome names from files.
      			Example: Xci3:Xeu8:XamC
      inseqs (paths):	Sequences to scan (input).  Each argument will be
      			considered a single genome, and the values of
			'names' will be applied.  The order of the inseqs
			must be the same of the names.
			Example: /data/Xci3.fa /data/Xeu8.fa /data/XamC.fa
      
HELP
   ;exit;
}

