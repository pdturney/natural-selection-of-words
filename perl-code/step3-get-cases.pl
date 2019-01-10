#
# step3-get-cases.pl
#
# - group words into synsets
#
# Peter Turney
# October 2, 2018
#
use strict;
use warnings;
#
# use WordNet::QueryData - direct Perl interface to WordNet database
#
# - see http://cpansearch.perl.org/src/JRENNIE/WordNet-QueryData-1.49/README
# - install WordNet 3.0 in C:\Program Files\WordNet\3.0
# - install Strawberry Perl for Windows 10
# - run > cpan  WordNet::QueryData
#
use WordNet::QueryData;
#
my $wn = WordNet::QueryData->new(noload => 0); # load words into memory for speed
#
# read in the time periods from the configuration file
#
# <period name> <begin> <end>
#
# A 1800 1810
# B 1850 1860
# C 1900 1910
# D 1950 1960
# E 2000 2010
#
my $config_file_name = "configuration.txt";
#
my @periods = ();
#
open(my $config_file, "<", $config_file_name) or die "Could not open file: $config_file_name\n";
#
while (my $line = <$config_file>) {
  chop($line);
  if ($line =~ /^\#/) { next; } # skip comment lines
  if ($line !~ /^\S+\s+\S+\s+\S+$/) { next; } # line must contain exactly three items
  my ($name, $start, $stop) = split(/\s+/, $line);
  push(@periods, "$start-$stop");
}
#
close $config_file;
#
# print to standard output for verification
#
foreach my $period (@periods) {
  print "period $period\n";
}
#
# input file of sums for selected years
#
my $in_file_name = "../perl-output/step2-sum-years.txt";
#
open(my $in_file, "<", $in_file_name) or die "Could not open file: $in_file_name\n";
#
# read year sums into a hash table
#
print "reading $in_file_name ...\n";
#
# read the sums from the body of $in_file
#
my @word_list = ();
my %word_sums = ();
#
# use WordNet format for words: "clarity_NOUN" --> "clarity#n#1"
#
# - assume every word has its primary sense ("#1") for the given part of speech ("#n")
#
my %tag_map = ("NOUN" => "#n#1", "VERB" => "#v#1", "ADJ" => "#a#1", "ADV" => "#r#1");
#
while (my $line = <$in_file>) {
  chop($line); # remove "\n" from end of line
  my @sums = split(/\t/, $line);
  my $word = shift(@sums);
  my ($bare_word, $google_tag) = split(/\_/, $word);
  if (! defined($tag_map{$google_tag})) { die "Could not decode tag: $google_tag\n"; }
  my $wn_word = $bare_word . $tag_map{$google_tag};
  $word_sums{$wn_word} = join("\t", @sums);
  push(@word_list, $wn_word);
}
#
close $in_file;
#
print "... done reading $in_file_name.\n";
#
# for each word in @word_list, find its synset
#
# - we only want to process each synset once, so we use the gloss of a synset
#   as a unique identifier of the synset
#
# output file of words within synsets
#
my $pretty_file_name = "../perl-output/step3-cases-pretty.txt";
my $clean_file_name = "../perl-output/step3-cases-clean.txt";
#
open(my $pretty_file, ">", $pretty_file_name) or die "Could not open file: $pretty_file_name\n";
open(my $clean_file, ">", $clean_file_name) or die "Could not open file: $clean_file_name\n";
#
print "writing $pretty_file_name and $clean_file_name ...\n";
#
my %known_synsets = (); # synsets that we've seen so far
#
my $num_cases = 0;
#
foreach my $wn_word (@word_list) {
  # - skip this word if we have already processed its synset
  # - use the gloss as an identifier of the synset
  my @glosses = $wn->querySense($wn_word, "glos");
  my $gloss = $glosses[0];
  if (defined($known_synsets{$gloss})) { next; }
  # - mark this synset as processed
  $known_synsets{$gloss} = 1;
  # - look up the members of this synset
  my @syns = $wn->querySense($wn_word, "syns");
  # - a synset is only used if it passes a series of tests (given below)
  # - start by assuming it passes all tests, until it fails
  my $passes_all_tests = 1; 
  foreach my $syn (@syns) {
    # - there must be at least two words in the synset @syns
    my $synset_size = scalar(@syns);
    if ($synset_size < 2) { 
      $passes_all_tests = 0;
      last;
    }
    # - the word $syn must be a primary sense in this synset @syns
    if ($syn !~ /\#1$/) {
      $passes_all_tests = 0;
      last;
    }
    # - the word $syn cannot have a secondary sense with the same part of speech
    my $pos_word = $syn;
    $pos_word =~ s/\#1$//; # strip off sense number of $syn but leave part of speech
    my @senses = $wn->querySense($pos_word); # make a list of senses with the same POS
    my $num_senses = scalar(@senses);
    if ($num_senses > 1) {
      $passes_all_tests = 0;
      last;
    }
    # - require all lower case alphabetic (eliminate words with spaces,
    #   apostrophes, numbers, capital letters, etc.)
    if ($syn !~ /^[a-z]+\#\S\#\d$/) {
      $passes_all_tests = 0;
      last;
    }
    # - skip words that have a frequency of zero in all periods
    if (! defined($word_sums{$syn})) {
      $passes_all_tests = 0;
      last;
    }
  }
  #
  # - if not all tests were passed, move on to the next word in @word_list
  #
  if ($passes_all_tests == 0) { next; }
  #
  # - if we reach this point, we have passed all the tests, so print the results
  #
  $num_cases++;
  #
  my @sorted_syns = sort { $a cmp $b } @syns;
  #
  print $pretty_file "($num_cases) candidates = " . join(", ", @sorted_syns) . "\n\n";
  print $pretty_file "gloss = $gloss\n\n";
  print $pretty_file "synset = " . join(", ", @syns) . "\n\n";
  #
  # table header
  #
  my @pretty_header = ();
  push(@pretty_header, sprintf("%-20s", "Word"));
  foreach my $period (@periods) {
    push(@pretty_header, sprintf("%9s", $period));
  }
  push(@pretty_header, sprintf("%6s", "SemCor"));
  push(@pretty_header, sprintf("%6s", "Senses"));
  #
  print $pretty_file join(" ", @pretty_header) . "\n";
  #
  foreach my $syn (@sorted_syns) {
    #
    # find SemCor (Semantic Concordance corpus) frequency of $syn
    #
    my $semcor_freq = $wn->frequency($syn);
    #
    # find number of senses of syn
    #
    my $base_word = $syn; # "clarity#n#1"
    $base_word =~ s/\#\d+$//; # "clarity#n"
    my @base_senses = $wn->querySense($base_word); # find all sense numbers of "clarity#n"
    my $num_senses = scalar(@base_senses); # 2 senses
    #
    # table body
    #
    my @pretty_body = ();
    push(@pretty_body, sprintf("%-20s", $syn));
    if (! defined($word_sums{$syn})) { die "Unexpected word: $syn\n"; }
    my @sums = split(/\t/, $word_sums{$syn});
    foreach my $sum (@sums) {
      push(@pretty_body, sprintf("%9s", $sum));
    }
    push(@pretty_body, sprintf("%6s", $semcor_freq));
    push(@pretty_body, sprintf("%6s", $num_senses));
    
    print $pretty_file join(" ", @pretty_body) . "\n";
    #
  }
  #
  print $pretty_file "\n";
  #
  # - now write stuff for $clean_file
  #
  #  Format: "<id number> <candidate set>"
  #
  #  Example: "16 accomplishable#a#1|achievable#a#1|doable#a#1"
  #
  print $clean_file $num_cases . "\t" . join("|", @sorted_syns) . "\n";
  #
}
#
# close files
#
close $pretty_file;
close $clean_file;
#
print "... done writing $pretty_file_name and $clean_file_name.\n\n";
#
#