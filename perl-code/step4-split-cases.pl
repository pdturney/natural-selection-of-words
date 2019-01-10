#
# step4-split-cases.pl
#
# - split cases into train and test files
#
# Peter Turney
# October 4, 2018
#
use strict;
use warnings;
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
    # "train2" --> "step4-train2.txt"
    my $extended_file_name = "../perl-output/step4-$file_name.txt"; 
    push(@file_names, $extended_file_name);
    $file_name_to_group{$extended_file_name} = "$past $present $future";
  }
}
#
close $config_file;
#
# input file of year sums
#
my $sum_file_name = "../perl-output/step2-sum-years.txt";
#
open(my $sum_file, "<", $sum_file_name) or die "Could not open file: $sum_file_name\n";
#
# read year sums into a hash table
#
print "reading $sum_file_name ...\n";
#
# read the sums from the body of $sum_file
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
while (my $line = <$sum_file>) {
  #
  # example: abandon_VERB	24674	125276	201264	228192	1291586
  #
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
close $sum_file;
#
print "... done reading $sum_file_name.\n";
#
# input file of clean cases
#
my $case_file_name = "../perl-output/step3-cases-clean.txt";
#
# read clean cases into a list
#
open(my $case_file, "<", $case_file_name) or die "Could not open file: $case_file_name\n";
#
print "reading $case_file_name ...\n";
#
# file format:
#
# 1	abaft#r#1|aft#r#1
# 2	abandon#n#1|unconstraint#n#1|wantonness#n#1
# 3	abandoned#a#1|deserted#a#1
#
my @case_list = ();
#
while (my $line = <$case_file>) {
  chop($line);
  push(@case_list, $line);
}
#
close $case_file;
#
print "... done reading $case_file_name.\n";
#
# write out the training and testing files
#
foreach my $extended_file_name (@file_names) { 
  #
  # for this file, which periods consitute the past, present, and future?
  #
  # example: "step4-train2.txt" --> ("B", "C", "D")
  #
  my @local_period_names = split(/\s/, $file_name_to_group{$extended_file_name});
  #
  # convert period names to positions in the sum file "step2-sum-years.txt"
  #
  # example: A --> 0, B --> 1, ... 
  #
  my @positions = ();
  foreach my $period_name (@local_period_names) {
    push(@positions, $period_name_to_position{$period_name});
  }
  #
  open (my $extended_file, ">", $extended_file_name) or die "Could not open file: $extended_file_name\n";
  #
  print "writing to $extended_file_name ...\n";
  #
  # show configuration
  #
  print $extended_file "#\n";
  print $extended_file "# current file: $extended_file_name\n";
  print $extended_file "#\n";
  foreach my $period_name (@period_names) {
    my $dates = $period_name_to_dates{$period_name};
    print $extended_file "# period $period_name = $dates\n"; 
  }
  print $extended_file "#\n";
  foreach my $file_name (@file_names) {
    my $periods = $file_name_to_group{$file_name};
    $periods =~ s/\s+/\, /g;
    print $extended_file "# $file_name = {$periods}\n";
  }
  print $extended_file "#\n";
  print $extended_file "# SEE STATS AT BOTTOM OF FILE\n";
  print $extended_file "#\n";
  #
  my $num_stable = 0; # total number of stable synsets
  my $num_changed = 0; # total number of changed synsets
  my $num_words = 0; # total number of words
  #
  foreach my $case (@case_list) {
    #
    # example: 2 abandon#n#1|unconstraint#n#1|wantonness#n#1
    #
    my ($case_num, $synset) = split(/\s/, $case);
    my @syns = split(/\|/, $synset);
    #
    # for each synonym in @syns, find its frequency for the past, present,
    # and future periods
    #
    my %syn_past_sum = ();
    my %syn_present_sum = ();
    my %syn_future_sum = ();
    #
    my $syn_present_nonzero = 1;
    foreach my $syn (@syns) {
      if (! defined($word_sums{$syn})) { die "Could not find $syn in $sum_file_name\n"; }
      my @sums = split(/\t/, $word_sums{$syn});
      $syn_past_sum{$syn} = $sums[$positions[0]];
      $syn_present_sum{$syn} = $sums[$positions[1]];
      $syn_future_sum{$syn} = $sums[$positions[2]];
      if ($syn_present_sum{$syn} == 0) { $syn_present_nonzero = 0; }
    }
    # - skip if any member of @syns is unknown in the present
    if ($syn_present_nonzero == 0) { next; }
    #
    # we want to find the winning word (highest frequency) in the present period
    # and the future period, but we cannot allow ties for first place in either period
    #
    # - present period winner
    my @sorted_present_words = sort { $syn_present_sum{$b} <=> $syn_present_sum{$a} } @syns;
    my $present_first_place_word = $sorted_present_words[0];
    my $present_second_place_word = $sorted_present_words[1];
    my $present_first_place_sum = $syn_present_sum{$present_first_place_word};
    my $present_second_place_sum = $syn_present_sum{$present_second_place_word};
    # - skip if max is zero
    if ($present_first_place_sum == 0) { next; }
    # - skip if first and second are tied
    if ($present_first_place_sum == $present_second_place_sum) { next; }
    # - future period winner
    my @sorted_future_words = sort { $syn_future_sum{$b} <=> $syn_future_sum{$a} } @syns;
    my $future_first_place_word = $sorted_future_words[0];
    my $future_second_place_word = $sorted_future_words[1];
    my $future_first_place_sum = $syn_future_sum{$future_first_place_word};
    my $future_second_place_sum = $syn_future_sum{$future_second_place_word};
    # - skip if max is zero
    if ($future_first_place_sum == 0) { next; }
    # - skip if first and second are tied
    if ($future_first_place_sum == $future_second_place_sum) { next; }
    # - if we reach this point, we have passed all the tests, so print the results
    # - first, echo $case (e.g., "2 abandon#n#1|unconstraint#n#1|wantonness#n#1")
    print $extended_file $case . "\n";
    # - second, print out the present and future winners
    my $status = "";
    if ($present_first_place_word ne $future_first_place_word) { 
      $num_changed++;
      $status = "CHANGED";
    } else {
      $num_stable++;
      $status = "STABLE";
    }
    print $extended_file "$present_first_place_word --> $future_first_place_word $status\n";
    # - third, print out the past, present, and future sums for each $syn
    foreach my $syn (@syns) {
      my $past_sum = $syn_past_sum{$syn};
      my $present_sum = $syn_present_sum{$syn};
      my $future_sum = $syn_future_sum{$syn};
      print $extended_file "$syn $past_sum $present_sum $future_sum\n";
      $num_words++; # increment the total number of words
    }
    # - print a blank separator line
    print $extended_file "\n";
    #
  }
  #
  # show summary stats
  #
  my $total = $num_changed + $num_stable;
  my $pct_changed = 100 * $num_changed / $total;
  my $pct_stable = 100 * $num_stable / $total;
  my $words_per_syn = $num_words / $total;
  #
  print "CHANGED: $num_changed ($pct_changed \%)\n";
  print "STABLE:  $num_stable ($pct_stable \%)\n";
  print "TOTAL:   $total\n";
  #
  print $extended_file "#\n";
  print $extended_file "# SYNSET STATISTICS\n";
  print $extended_file "#\n";
  print $extended_file "# CHANGED: $num_changed ($pct_changed \%)\n";
  print $extended_file "# STABLE:  $num_stable ($pct_stable \%)\n";
  print $extended_file "# TOTAL:   $total\n";
  print $extended_file "#\n";
  print $extended_file "# WORD STATISTICS\n";
  print $extended_file "#\n";
  print $extended_file "# TOTAL NUM WORDS:  $num_words\n";
  print $extended_file "# WORDS PER SYNSET: $words_per_syn\n";
  print $extended_file "#\n";
  #
  close $extended_file;
  #
  print "... done writing to $extended_file_name.\n";
  #
}
#