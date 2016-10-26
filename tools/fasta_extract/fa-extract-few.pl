#!/usr/bin/perl -w
use strict;
use Bio::SeqIO;

my(@Options, $verbose, $inverse, $file,$list,$exact);
setOptions();

my $in = Bio::SeqIO->new(-file=>$file, -format=>'Fasta');
my $out = Bio::SeqIO->new(-fh=>\*STDOUT, -format=>'Fasta');
my $nread=0;
my $nwrote=0;

my $pattern = join('|', @ARGV);

if ( $list) {
    my @list;
    open my $in,'<',$list;
    while ( <$in>) {
        chomp;
        push @list,$_;
    }
    close $in;
    $pattern = join ('|',@list);
}

while (my $seq = $in->next_seq) {
  $nread++;
  my $match = ($seq->description =~ m/($pattern)/ or $seq->display_id =~ m/($pattern)/);
  if ($exact) {
	$match = ($seq->display_id =~ m/^($pattern)$/);
  }
  #print STDERR "Found match: ",$seq->display_id, " ", $seq->description, "\n" if $verbose;
  if ($match ^ $inverse) {  # rare use for XOR !
    $out->write_seq($seq);
    $nwrote++;
  }
} 

#print STDERR "Read $nread sequences, wrote $nwrote, with pattern: $pattern\n";
exit(0);
#----------------------------------------------------------------------
# Option setting routines

sub setOptions {
  use Getopt::Long;

  @Options = (
    {OPT=>"h|help",    VAR=>\&usage,             DESC=>"This help"},
    {OPT=>"verbose!",  VAR=>\$verbose, DEFAULT=>0, DESC=>"Verbose"},
    {OPT=>"v|inverse!",  VAR=>\$inverse, DEFAULT=>0, DESC=>"Output NON-matching sequences instead"},
    {OPT=>"f|file=s",   VAR=>\$file, DEFAULT=>"", DESC=>"The fasta file to extract sequences from"},
    {OPT=>"exact",   VAR=>\$exact, DEFAULT=>"", DESC=>"Exact matches for display id only"},
    {OPT=>"l|list=s",   VAR=>\$list, DEFAULT=>"", DESC=>"List of pattern to look from"},
  );

  (!@ARGV) && (usage());

  &GetOptions(map {$_->{OPT}, $_->{VAR}} @Options) || usage();

  # Now setup default values.
  foreach (@Options) {
    if (defined($_->{DEFAULT}) && !defined(${$_->{VAR}})) {
      ${$_->{VAR}} = $_->{DEFAULT};
    }
  }
}

sub usage {
  print "Usage: $0 [options] id1 [id2 ...] < input.fasta > output.fasta\n";
  foreach (@Options) {
    printf "  --%-13s %s%s.\n",$_->{OPT},$_->{DESC},
           defined($_->{DEFAULT}) ? " (default '$_->{DEFAULT}')" : "";
  }
  exit(1);
}
 
#----------------------------------------------------------------------
