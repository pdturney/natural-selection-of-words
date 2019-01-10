#
# step5-make-features.pl
#
# - generate features for the cases, in a format suitable
#   for input to Weka, the Attribute-Relation File Format (ARFF)
#
# Peter Turney
# October 1, 2018
#
use strict;
use warnings;
#
use Lingua::EN::Syllable; # syllable counter
#
# read in the time periods and training and testing groups from the configuration file
#
# <period name> <begin> <end>
#
# A 1800 1810
# B 1850 1860
# C 1900 1910
# D 1950 1960
# E 2000 2010
#
# <file name>  <period 1 name> <period 2 name> <period 3 name>
#
# [train/test] [past]          [present]       [future]
#
# train1 A B C
# test1  B C D
# train2 B C D
# test2  C D E
#
my $config_file_name = "configuration.txt";
#
my @period_names = (); # A, B, C, ...
my @file_names = (); # train1, test1, ...
my %file_name_to_group = ();
my %period_name_to_position = (); # position of period name in lines in "step2-sum-years.txt"
my %period_name_to_dates = ();
#
open(my $config_file, "<", $config_file_name) or die "Could not open file: $config_file_name\n";
#
my $position = 0;
#
while (my $line = <$config_file>) {
  chop($line);
  if ($line =~ /^\#/) { next; } # skip comment lines
  if ($line =~ /^\S+\s+\S+\s+\S+$/) { # A 1800 1810
    my ($period_name, $start, $stop) = split(/\s+/, $line);
    push(@period_names, $period_name);
    $period_name_to_position{$period_name} = $position; # A --> 0, B --> 1, ...
    $period_name_to_dates{$period_name} = "$start-$stop";
    $position++;
  }
  if ($line =~ /^\S+\s+\S+\s+\S+\s+\S+$/) { # train1 A B C
    my ($file_name, $past, $present, $future) = split(/\s+/, $line);
    push(@file_names, $file_name);
    $file_name_to_group{$file_name} = "$past $present $future";
  }
}
#
close $config_file;
#
# read in the birthdate of each word (according to Google Ngrams)
#
my $birth_file_name = "../perl-output/step1-birthdays.txt";
#
open(my $birth_file, "<", $birth_file_name) or die "Could not open file: $birth_file_name\n";
#
print "reading $birth_file_name ...\n";
#
my %word_to_birth = ();
#
while (my $line = <$birth_file>) {
  chop($line);
  my ($word, $year) = split(/\t/, $line); # androphobia_NOUN	1908
  $word_to_birth{$word} = $year;
}
#
close $birth_file;
#
print "... done reading $birth_file_name.\n";
#
# read in the CATVAR variations
#
my $catvar_file_name = "../perl-output/wordnet-catvar.txt";
#
open(my $catvar_file, "<", $catvar_file_name) or die "Could not open file: $catvar_file_name\n";
#
print "reading $catvar_file_name ...\n";
#
my %word_to_variations = ();
#
while (my $line = <$catvar_file>) {
  chop($line);
  my ($word, $num_vars) = split(/\t/, $line); # abandoned#a#1	4
  my @variations = ();
  for (my $i = 0; $i < $num_vars; $i++) {
    $line = <$catvar_file>; # abandon_N	(type 110)
    $line =~ s/^\t//; # these lines are indented with tabs
    my ($variation, $type) = split(/\t/, $line);
    push(@variations, $variation); # abandon_N
  }
  $word_to_variations{$word} = join(" ", @variations); # "abandon_N abandon_V abandoned_AJ abandonment_N"
}
#
close $catvar_file;
#
print "... done reading $catvar_file_name.\n";
#
# process the train and test files
#
my %word_past_sum = ();
my %word_present_sum = ();
my %word_future_sum = ();
#
foreach my $file_name (@file_names) { 
  #
  # $file_name = train1, test1, train2, test2, ...
  #
  my $in_file_name = "../perl-output/step4-$file_name.txt"; 
  my $out_file_name = "../perl-output/step5-$file_name-features.arff";
  #
  open(my $in_file, "<", $in_file_name) or die "Could not open file: $in_file_name\n";
  open(my $out_file, ">", $out_file_name) or die "Could not open file: $out_file_name\n";
  #
  print "reading $in_file_name and writing $out_file_name ...\n";
  #
  # find the present year, relative to the current file name
  #
  my $group = $file_name_to_group{$file_name}; # train2 --> B C D
  my @period_names = split(/\s+/, $group); # (B, C, D)
  my $present_period_name = $period_names[1]; # C
  my $present_dates = $period_name_to_dates{$present_period_name}; # "$start-$stop" -- "1950-1960"
  my ($present_start, $present_stop) = split(/\-/, $present_dates);
  #
  # make a header for the ARFF file
  #
  print $out_file "%\n";
  print $out_file "% current file: $out_file_name\n";
  print $out_file "%\n";
  foreach my $period_name (@period_names) {
    my $dates = $period_name_to_dates{$period_name};
    print $out_file "% period $period_name = $dates\n"; 
  }
  print $out_file "%\n";
  foreach my $file_name (@file_names) {
    my $periods = $file_name_to_group{$file_name};
    $periods =~ s/\s+/\, /g;
    print $out_file "% $file_name = {$periods}\n";
  }
  print $out_file "%\n";
  #
  print $out_file "\@RELATION evolution-of-words\n";
  #
  print $out_file "\@ATTRIBUTE synset-id-number NUMERIC\n";
  print $out_file "\@ATTRIBUTE word STRING\n";
  print $out_file "\@ATTRIBUTE normalized-length NUMERIC\n";
  print $out_file "\@ATTRIBUTE unique-ngrams STRING\n";
  print $out_file "\@ATTRIBUTE fraction-ngrams-shared NUMERIC\n";
  print $out_file "\@ATTRIBUTE syllable-count NUMERIC\n";
  print $out_file "\@ATTRIBUTE relative-growth NUMERIC\n";
  print $out_file "\@ATTRIBUTE linear-extrapolation NUMERIC\n";
  print $out_file "\@ATTRIBUTE present-age NUMERIC\n";
  print $out_file "\@ATTRIBUTE number-catvar-variations NUMERIC\n";
  print $out_file "\@ATTRIBUTE class {0,1}\n";
  #
  print $out_file "\@DATA\n";
  #
  # write out the feature vectors for the body of the ARFF file
  #
  while (my $line = <$in_file>) {
    #
    # skip comments and blank lines
    #
    if ($line =~ /^\#/) { next; }
    if ($line =~ /^\s*$/) { next; }
    #
    chop($line); # remove "\n" from end of line
    # 
    # example of input lines:
    #
    # 2	abandon#n#1|unconstraint#n#1|wantonness#n#1
    # wantonness#n#1 --> wantonness#n#1 STABLE
    # abandon#n#1 76 1686 10211
    # unconstraint#n#1 20 57 472
    # wantonness#n#1 2850 7771 10921
    #
    # - first line
    my ($id, $synset) = split(/\t/, $line);
    my @syns = split(/\|/, $synset);
    # - second line
    $line = <$in_file>;
    chop($line);
    my ($present_winner, $arrow, $future_winner, $status) = split(/\s+/, $line);
    # - remaining lines
    my $num_words = scalar(@syns);
    for (my $i = 0; $i < $num_words; $i++) {
      $line = <$in_file>;
      chop($line);
      my ($word, $past_sum, $present_sum, $future_sum) = split(/\s+/, $line);
      $word_past_sum{$word} = $past_sum;
      $word_present_sum{$word} = $present_sum;
      $word_future_sum{$word} = $future_sum;
    }  
    #
    # each member of the synset @syns maps to a separate feature vector
    #
    # - all members of a synset get the same ID number, to show that they
    #   belong together
    #
    foreach my $word (@syns) {
      #
      # @ATTRIBUTE synset-id-number NUMERIC
      #
      print $out_file $id . ",";
      #
      # @ATTRIBUTE word STRING
      #
      print $out_file "\'" . $word . "\',";
      #
      # @ATTRIBUTE normalized-length NUMERIC
      #
      print $out_file norm_len($word, @syns) . ",";
      #
      # @ATTRIBUTE unique-ngrams STRING
      #
      print $out_file "\'" . unique_ngrams($word, @syns) . "\',";
      #
      # @ATTRIBUTE fraction-ngrams-shared NUMERIC
      #
      print $out_file fraction_ngrams_shared($word, @syns) . ",";
      #
      # @ATTRIBUTE syllable-count NUMERIC
      #
      print $out_file syllable(clean_word($word)) . ",";
      #
      # @ATTRIBUTE relative-growth NUMERIC
      #
      print $out_file relative_growth($word, @syns) . ",";
      #
      # @ATTRIBUTE linear-extrapolation NUMERIC
      #
      print $out_file linear_extrapolation(1.0, $word, @syns) . ","; 
      #
      # @ATTRIBUTE present-age NUMERIC
      #
      print $out_file present_age($word, $present_stop) . ",";
      #
      # @ATTRIBUTE number-catvar-variations NUMERIC
      #
      print $out_file number_catvar($word, $present_stop) . ",";
      #
      # @ATTRIBUTE class {0,1}
      #
      print $out_file class($word, $future_winner) . "\n"
      #
    }
    #
  }
  #
  close $in_file;
  close $out_file;
  #
  print "... done reading $in_file_name and writing $out_file_name.\n";
  #
}
#
# subroutines for calculating features
# ------------------------------------
#
# bracketed_word($word)
#
# - "clarity#n#1" --> "|clarity|"
# - use "|" to mark beginning and end of word
#
sub bracketed_word {
  my ($word) = @_;
  return "|" . clean_word($word) . "|";
}
#
# clean_word($word)
#
# - remove WordNet info
# - "clarity#n#1" --> "clarity"
#
sub clean_word {
  my ($word) = @_;
  $word =~ s/\#.+$//;
  return $word;
}
#
# norm_len($word, @syns)
#
# - normalize string length of $word by the maximum length
#
sub norm_len {
  my ($word, @syns) = @_;
  my $clean_word = clean_word($word);
  my $max_len = length($clean_word);
  foreach my $choice (@syns) {
    my $clean_choice = clean_word($choice);
    $max_len = max($max_len, length($clean_choice));
  }
  return sprintf("%f", length($clean_word) / $max_len);
}
#
# unique_ngrams($word, @syns)
#
sub unique_ngrams {
  my ($word, @syns) = @_;
  my @given_word_ngrams = ngrams($word);
  my @other_words_ngrams = ();
  foreach my $other_word (@syns) {
    if ($other_word ne $word) { push(@other_words_ngrams, ngrams($other_word)); }
  }
  my @unique_given_ngrams = set_difference(\@given_word_ngrams, \@other_words_ngrams);
  return join(" ", @unique_given_ngrams);
}
#
# fraction_ngrams_shared($word, @syns)
#
sub fraction_ngrams_shared {
  my ($word, @syns) = @_;
  my @given_word_ngrams = ngrams($word);
  my @other_words_ngrams = ();
  foreach my $other_word (@syns) {
    if ($other_word ne $word) { push(@other_words_ngrams, ngrams($other_word)); }
  }
  my @unique_given_ngrams = set_difference(\@given_word_ngrams, \@other_words_ngrams);
  my $fraction_unique = scalar(@unique_given_ngrams) / scalar(@given_word_ngrams);
  return sprintf("%f", 1.0 - $fraction_unique);
}
#
# class($word, $future_winner)
#
# - our aim here is to guess which word in @syns is the future winner
#
sub class {
  my ($word, $future_winner) = @_;
  if ($word eq $future_winner) { return 1; }
  return 0;
}
#
# ngrams($word)
#
sub ngrams {
  my ($word) = @_;
  my %ngram_hash = ();
  my $bracketed_word = bracketed_word($word);
  my $len = length($bracketed_word);
  # - letter 3-grams
  for (my $i = 0; $i < $len - 2; $i++) { $ngram_hash{substr($bracketed_word, $i, 3)} = 1; }
  return (keys %ngram_hash);
}
#
# set_difference(\@given_word_ngrams, \@other_words_ngrams)
#
# - \@given_word_ngrams and \@other_words_ngrams are passed by reference and must be dereferenced
#
sub set_difference {
  my ($given_ref, $other_ref) = @_;
  my %ngram_hash = ();
  foreach my $given_word (@{$given_ref}) { # dereference
    $ngram_hash{$given_word} = 1;
  }
  foreach my $other_word (@{$other_ref}) { # dereference
    if (defined($ngram_hash{$other_word})) {
      delete $ngram_hash{$other_word};
    }
  }
  return (keys %ngram_hash);
}
#
# relative_growth($word, @syns)
#
# - compare the past frequency to the present frequency
# - frequency is relative to synset
#
sub relative_growth {
  my ($word, @syns) = @_;
  my $word_past_freq = $word_past_sum{$word};
  my $word_present_freq = $word_present_sum{$word};
  my $synset_past_freq = 0;
  my $synset_present_freq = 0;
  foreach my $syn (@syns) {
    $synset_past_freq += $word_past_sum{$syn};
    $synset_present_freq += $word_present_sum{$syn};
  }
  my $word_past_relative_freq = 0;
  if ($synset_past_freq > 0) { 
    $word_past_relative_freq = $word_past_freq / $synset_past_freq; 
  }
  my $word_present_relative_freq = 0;
  if ($synset_present_freq > 0) { 
    $word_present_relative_freq = $word_present_freq / $synset_present_freq; 
  }
  return $word_present_relative_freq - $word_past_relative_freq;
}
#
# linear_extrapolation($alpha, $word, @syns)
#
# - use linear model to estimate future from present and past
# - delta = present - past
# - future = present + delta = 2 * present - past
#
# - alpha -- 1.0 = neutral; 0.5 = conservative; 1.5 = aggressive
#
# - future = ((1.0 + alpha) * present) - (alpha * past)
#
sub linear_extrapolation {
  my ($alpha, $word, @syns) = @_;
  my $word_past_freq = $word_past_sum{$word};
  my $word_present_freq = $word_present_sum{$word};
  my $synset_past_freq = 0;
  my $synset_present_freq = 0;
  foreach my $syn (@syns) {
    $synset_past_freq += $word_past_sum{$syn};
    $synset_present_freq += $word_present_sum{$syn};
  }
  my $word_past_relative_freq = 0;
  if ($synset_past_freq > 0) { 
    $word_past_relative_freq = $word_past_freq / $synset_past_freq; 
  }
  my $word_present_relative_freq = 0;
  if ($synset_present_freq > 0) { 
    $word_present_relative_freq = $word_present_freq / $synset_present_freq; 
  }
  my $word_future_relative_freq = ((1.0 + $alpha) * $word_present_relative_freq) 
                                - ($alpha * $word_past_relative_freq);
  return $word_future_relative_freq
}
#
# present_age($word, $present_stop)
#
sub present_age {
  my ($word, $present_stop) = @_;
  my $google_word = $word;
  $google_word =~ s/\#n\#1$/\_NOUN/; # convert WordNet tags to Google tags
  $google_word =~ s/\#v\#1$/\_VERB/;
  $google_word =~ s/\#a\#1$/\_ADJ/;
  $google_word =~ s/\#r\#1$/\_ADV/;
  if (! defined($word_to_birth{$google_word})) { die "Word not found in $birth_file_name: $google_word\n"; }
  my $google_birth = $word_to_birth{$google_word};
  my $present_age = $present_stop - $google_birth;
  if ($present_age < 0) { die "Word was not known at this time: $google_word - $google_birth\n"; }
  return $present_age;
}
#
# number_catvar($word, $present_stop)
#
sub number_catvar {
  my ($word, $present_stop) = @_;
  if (! defined($word_to_variations{$word})) { return 1; }
  my @variations = split(/\s+/, $word_to_variations{$word}); # abandoned#a#1 --> "abandon_N abandon_V ..."
  # - count how many variations were known before $present_stop
  my $count = 0;
  foreach my $variation (@variations) {
    $variation =~ s/\_N$/\_NOUN/; # convert CATVAR tags to Google tags
    $variation =~ s/\_V$/\_VERB/;
    $variation =~ s/\_AJ$/\_ADJ/;
    $variation =~ s/\_AV$/\_ADV/;
    if (! defined($word_to_birth{$variation})) { next; }
    if ($word_to_birth{$variation} <= $present_stop) { $count++; }
  }
  if ($count == 0) { return 1; }
  return $count;
}
#
# max(@values)
#
sub max {
  my @values = @_;
  my @sorted = sort { $b <=> $a } @values; # sort in descending order
  return $sorted[0];
}
#
# min(@values)
#
sub min {
  my @values = @_;
  my @sorted = sort { $a <=> $b } @values; # sort in ascending order
  return $sorted[0];
}
#