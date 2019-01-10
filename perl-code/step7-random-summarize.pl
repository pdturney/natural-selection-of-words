#
# step7-random-summarize.pl
#
# - summarize the results of random guessing on the testing files
#
# Peter Turney
# October 1, 2018
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
    push(@file_names, $file_name);
    $file_name_to_group{$file_name} = "$past $present $future";
  }
}
#
close $config_file;
#
# process the training and testing files
#
# - this assumes that the configuration file has the file names
#   in order: train1, test1, train2, test2, train3, test3, ...
#
while (scalar(@file_names) > 0) {
  #
  my $train = shift(@file_names);
  my $test = shift(@file_names);
  #
  # input files
  #
  my $synset_file_name = "../perl-output/step4-$test.txt";
  my $probality_file_name = "../perl-output/step6-$test-random.txt";
  #
  # output file
  #
  my $summary_file_name = "../perl-output/step7-$test-random-summary.txt";
  #
  # read in the probability information
  #
  print "reading probabilities from $probality_file_name ...\n";
  #
  my %word_to_probability = ();
  #
  open(my $probality_file, "<", $probality_file_name) or die "Could not open file: $probality_file_name\n";
  #
  while (my $line = <$probality_file>) {
    #
    # example of input line:
    #
    # "   1   1:0   1:0  0.793  (1206,baptistry#n#1,0.155196,0.155196,0.9,0.9,7,2)"
    #
    if ($line !~ /^\s+\d+/) { next; } # skip headers lines that don't start with a number
    chop($line); # remove "\n" from end of line
    $line =~ s/\+//; # remove "+" flag from line (indicates error in prediction)
    $line =~ s/^\s+//; # remove white space from beginning of line
    #
    my ($inst, $actual, $predicted, $probability, $vector) = split(/\s+/, $line);
    my @elements = split(/\,/, $vector);
    my $word = $elements[1]; # baptistry#n#1
    #
    # the probability value in $probability is the estimated confidence in the
    # prediction $predicted, but we want the probability to be the probability
    # that the word $word is the later winner, class 1, so we need to flip
    # the probability when $predicted is class 0
    #
    if ($predicted eq "1:0") { $probability = 1.0 - $probability; }
    #
    $word_to_probability{$word} = $probability;
    #
  }
  #
  close $probality_file;
  #
  print "... done reading $probality_file_name.\n";
  #
  # read in the synset information
  #
  print "reading $synset_file_name and writing $summary_file_name ...\n";
  #
  open(my $synset_file, "<", $synset_file_name) or die "Could not open file: $synset_file_name\n";
  open(my $summary_file, ">", $summary_file_name) or die "Could not open file: $summary_file_name\n";
  #
  my $num_changed_right = 0;
  my $num_changed_wrong = 0;
  my $num_stable_right = 0;
  my $num_stable_wrong = 0;
  #
  while (my $line = <$synset_file>) {
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
    my $line1 = $line;
    my ($id, $synset) = split(/\t/, $line);
    my @syns = split(/\|/, $synset);
    # - second line
    $line = <$synset_file>;
    chop($line);
    my $line2 = $line;
    my ($present_winner, $arrow, $future_winner, $status) = split(/\s+/, $line);
    # - remaining lines
    my $num_words = scalar(@syns);
    for (my $i = 0; $i < $num_words; $i++) {
      $line = <$synset_file>;
      chop($line);
      my ($word, $past_sum, $present_sum, $future_sum) = split(/\s+/, $line);
    }  
    #
    print $summary_file "$line1\n";
    print $summary_file "   TRUTH (present --> future): $line2\n";
    #
    my $best_guess = "";
    my $max_prob = 0.0;
    foreach my $syn (@syns) {
      if (defined($word_to_probability{$syn})) {
        my $prob = $word_to_probability{$syn};
        print $summary_file "   PROB($syn) = $prob\n";
        if ($prob >= $max_prob) {
          $max_prob = $prob;
          $best_guess = $syn;
        }
      } else {
        die "Could not find probability of $syn in $probality_file_name\n";
      }
    }
    my $result = "";
    if ($best_guess eq $future_winner) {
      $result = "RIGHT";
    } else {
      $result = "WRONG";
    }
    print $summary_file "   BEST GUESS (future): $best_guess ($max_prob) -- $result\n";
    #
    print $summary_file "\n";
    #
    if ($result eq "RIGHT") {
      if ($status eq "STABLE") {
        $num_stable_right++;
      } else {
        $num_changed_right++;
      }
    } else {
      if ($status eq "STABLE") {
        $num_stable_wrong++;
      } else {
        $num_changed_wrong++;
      }
    }
  }
  #
  # calculate summary statistics
  #
  my $total_stable = $num_stable_right + $num_stable_wrong;
  my $total_changed = $num_changed_right + $num_changed_wrong;
  my $total_right = $num_stable_right + $num_changed_right;
  my $total = $total_stable + $total_changed;
  my $num_guess_changed = $num_changed_right + $num_stable_wrong;
  #
  my $pct_stable_right = 100 * ($num_stable_right / $total_stable);
  my $pct_changed_right = 100 * ($num_changed_right / $total_changed);
  my $pct_right = 100 * ($total_right / $total);
  my $pct_stable = 100 * ($total_stable / $total);
  my $pct_changed = 100 * ($total_changed / $total);
  #
  my $precision_changed = 0;
  if ($num_guess_changed > 0) {
    $precision_changed = 100 * ($num_changed_right / $num_guess_changed);
  }
  # 
  my $recall_changed = 100 * ($num_changed_right / $total_changed);
  #
  my $f_score_changed = 0;
  if (($precision_changed + $recall_changed) > 0) {
    $f_score_changed = 2 * $precision_changed * $recall_changed / ($precision_changed + $recall_changed);
  }
  #
  print $summary_file "SUMMARY\n\n";
  print $summary_file "percent correct for STABLE:  " .
        sprintf("%7.2f  (%5d / %5d)\n", $pct_stable_right, $num_stable_right, $total_stable);
  print $summary_file "percent correct for CHANGED: " .
        sprintf("%7.2f  (%5d / %5d)\n", $pct_changed_right, $num_changed_right, $total_changed);
  print $summary_file "percent correct combined:    " .
        sprintf("%7.2f  (%5d / %5d)\n", $pct_right, $total_right, $total);
  print $summary_file "percent STABLE:              " .
        sprintf("%7.2f  (%5d / %5d)\n", $pct_stable, $total_stable, $total);
  print $summary_file "percent CHANGED:             " .
        sprintf("%7.2f  (%5d / %5d)\n", $pct_changed, $total_changed, $total);
  print $summary_file "precision for CHANGED:       " .
        sprintf("%7.2f  (%5d / %5d)\n", $precision_changed, $num_changed_right, $num_guess_changed);
  print $summary_file "recall for CHANGED:          " .
        sprintf("%7.2f  (%5d / %5d)\n", $recall_changed, $num_changed_right, $total_changed);
  print $summary_file "F-score for CHANGED:         " .
        sprintf("%7.2f\n", $f_score_changed);
  print $summary_file "\n\ntotal number of cases: $total\n\n";
  #
  close $synset_file;
  close $summary_file;
  #
  print "done reading $synset_file_name and writing $summary_file_name.\n";
  #
}
#