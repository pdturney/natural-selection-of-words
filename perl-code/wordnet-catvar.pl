#
# wordnet-catvar.pl
#
# - group words into synsets and find Catvar groups for the words
#
# Peter Turney
# October 1, 2018
#
use strict;
use warnings;
#
# output file for Catvar groups
#
my $out_file_name = "../perl-output/wordnet-catvar.txt";
#
# input file of Catvar database
#
# https://clipdemos.umiacs.umd.edu/catvar/
#
my $catvar_file_name = "../catvar/catvar21.signed"; 
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
print "getting words from WordNet ...\n";
#
# get unigram words from WordNet
# 
my @nouns = $wn->listAllWords("n");
my @verbs = $wn->listAllWords("v");
my @adjs = $wn->listAllWords("a");
my @advs = $wn->listAllWords("r");
#
# underscore "_" indicates two or more words; not a unigram
#
my $min_length = 3; # avoid "s" (second) and "m" (meter)
my @words = ();
my $word;
foreach $word (@nouns) { 
  if (length($word) < $min_length) { next; }
  if ($word !~ /_/) { push(@words, $word . "#n#1") }; 
}
foreach $word (@verbs) { 
  if (length($word) < $min_length) { next; }
  if ($word !~ /_/) { push(@words, $word . "#v#1") }; 
}
foreach $word (@adjs) { 
  if (length($word) < $min_length) { next; }
  if ($word !~ /_/) { push(@words, $word . "#a#1") }; 
}
foreach $word (@advs) { 
  if (length($word) < $min_length) { next; }
  if ($word !~ /_/) { push(@words, $word . "#r#1") }; 
}
#
# look for synsets that contain two or more primary senses ("#1")
#
my %known_synsets = (); # synsets that we've seen so far
my %qualifying_words = (); # the good stuff
#
foreach $word (@words) {
  # - skip this word if we have already processed its synset
  # - use the gloss as an identifier of the synset
  my @glosses = $wn->querySense($word, "glos");
  my $gloss = $glosses[0];
  if (defined($known_synsets{$gloss})) { next; }
  # - mark this synset as processed
  $known_synsets{$gloss} = 1;
  # - look up the members of this synset
  my @syns = $wn->querySense($word, "syns");
  # - extract from the synset those words that are primary senses ("#1")
  my @primary_syns = ();
  foreach my $syn (@syns) {
    if ($syn =~ /\#1$/) { 
      # - skip words that are not unigrams
      # - underscore "_" indicates two or more words; not a unigram
      if ($syn =~ /_/) { next; }
      # - skip hyphenated words
      if ($syn =~ /\-/) { next; }
      # - skip words with apostrophe (ne'er, ma'am)
      if ($syn =~ /\'/) { next; }
      # - skip words with periods (jr., sr. o.k.)
      if ($syn =~ /\./) { next; }
      # - skip capitalized words (no proper nouns)
      if ($syn =~ /[A-Z]/) { next; }
      # - skip words that don't start with a letter of the alphabet
      if ($syn !~ /^[a-z]/) { next; }
      # - if $syn has passed all tests ...
      push(@primary_syns, $syn); 
    }
  }
  # - skip this synset if there are less than two primary senses
  if (scalar(@primary_syns) < 2) { next; }
  # - add the words in @primary_syns to %qualifying_words
  foreach my $syn (@primary_syns) {
    $qualifying_words{$syn} = 1;
  }
}
#
# read the whole CATVAR file into a list, for speed,
# instead of reading it each time we have a new word
#
print "reading $catvar_file_name ...\n";
my @catvar_lines = ();
open(my $catvar_file, "<", $catvar_file_name) or die "Could not open file: $catvar_file_name\n";
while (my $line = <$catvar_file>) {
  chop($line); # remove "\n" from end of line
  push(@catvar_lines, $line);
}
close $catvar_file;
print "... done reading $catvar_file_name.\n";
#
# put the qualifying words in alphabetical order
#
my @alpha_words = sort { $a cmp $b } (keys %qualifying_words);
#
# look up Catvar words for each word and write them to the output file
#
open(my $out_file, ">", $out_file_name) or die "Could not open file: $out_file_name\n";
#
print "writing to $out_file_name ...\n";
#
foreach my $word (@alpha_words) {
  print "$word\n"; # show progress to user
  my @variations = catvar($word);
  my $num_vars = scalar(@variations);
  print $out_file "$word\t$num_vars\n";
  foreach my $var (@variations) {
    print $out_file "\t$var\n";
  }
}
# 
close $out_file;
#
print "... done writing to $out_file_name.\n";
#
# catvar($wordnet_word)
#
sub catvar {
  my ($wordnet_word) = @_; # "shutting#n#1"
  #
  my %variations = (); # use hash to remove possible duplicates
  #
  my $bare_word = $wordnet_word;
  $bare_word =~ s/\#.+$//; # "shutting#n#1" --> "shutting"
  #
  my $catvar_word = $wordnet_word;
  $catvar_word =~ s/\#n\#\d/\_N/; # "shutting#n#1" --> "shutting_N"
  $catvar_word =~ s/\#v\#\d/\_V/; # "shutting#v#1" --> "shutting_V"
  $catvar_word =~ s/\#a\#\d/\_AJ/; # "shutting#a#1" --> "shutting_AJ"
  $catvar_word =~ s/\#r\#\d/\_AV/; # "shutting#r#1" --> "shutting_AV"
  #
  # (0) make sure the input word is included in the output (type 1 = 10^0)
  #
  $variations{$catvar_word} = 1;
  #
  my $whole_word_pattern = "(^|\#)$bare_word\_\[A-Z\]+\%";
  my $whole_word_regex = qr/$whole_word_pattern/; # compile regex           
  #
  my @suffixes = ("able", "ability", "al", "alism", "ance", "ant", "ate", "ational", "ation", 
                  "ator", "ed", "ence", "er", "es", "est", "ful", "ible", "ibility", "ic", 
                  "ical", "icate", "ice", "ing", "ise", "iser", "ism", "ity", "ive", "iveness", 
                  "ization", "izer", "ize", "ly", "ment", "ness", "or", "ousness", "ous", 
                  "s", "tional", "tion", "ty");
  #
  my $truncation_pattern = "(" . join("|", @suffixes) . ")\$";
  my $truncated_word = $bare_word;
  $truncated_word =~ s/$truncation_pattern//;
  my $suffix_word_pattern = "(^|\#)$truncated_word\[a-z\]*\_\[A-Z\]+\%";
  my $suffix_word_regex = qr/$suffix_word_pattern/;
  #
  my $min_trunc_length = 6; # minimum length after truncation
  #
  foreach my $line (@catvar_lines) {
    #
    # (1) whole input word matches whole catvar word (type 10 = 10^1)
    #
    if ($line =~ /$whole_word_regex/) {
      my @vars = split("\#", $line);
      foreach my $var (@vars) {
        $var =~ s/\%\d+$//; # "legalize_V%27" --> "legalize_V"
        $variations{$var} += 10;
      }
    }  
    #
    # (2) input word with suffix (type 100 = 10^2)
    #
    if (length($truncated_word) >= $min_trunc_length) {
      if ($line =~ /$suffix_word_regex/) {
        my @vars = split("\#", $line);
        foreach my $var (@vars) {
          $var =~ s/\%\d+$//; # "legalize_V%27" --> "legalize_V"
          $variations{$var} += 100;
        }
      } 
    }
  }
  #
  my @results = ();
  while (my ($key, $value) = each(%variations)) {
    #
    # - we return $value for debugging purposes
    # - $value tells us how $key was generated
    #
    push(@results, "$key\t(type $value)");
  }
  # 
  return sort {$a cmp $b} @results;
}
#
