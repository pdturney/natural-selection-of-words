#
# step6-random-baseline.pl
#
# - generate a random baseline
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
  my $in_test_file_name = "../perl-output/step5-$test-features.arff";
  #
  # output file
  #
  my $out_results_file_name = "../perl-output/step6-$test-random.txt";
  #
  srand(1234); # random number seed, for repeatable results
  #
  open(my $in_file, "<", $in_test_file_name) or die "Could not open file: $in_test_file_name\n";
  open(my $out_file, ">", $out_results_file_name) or die "Could not open file: $out_results_file_name\n";
  #
  print "reading $in_test_file_name and writing $out_results_file_name ...\n";
  #
  # print out header for $out_file in same format as Weka NaiveBayes
  #
  print $out_file "\n\n=== Random baseline predictions on test data ===\n\n\n";
  print $out_file "    inst#     actual  predicted error prediction\n";
  #
  # read lines in $in_file and print out lines for $out_file
  #
  my $instance_num = 0;
  #
  while (my $line = <$in_file>) {
    #
    # skip over ARFF header
    #
    if ($line =~ /^\@/) { next; }
    if ($line =~ /^\%/) { next; }
    #
    # example of input line:
    #
    # "5887,'smallness#n#1','|smallness|',0.900000,1"
    #
    my @elements = split(/\,/, $line);
    my $class = pop(@elements); # remove class from end of input line
    my $vector = "(" . join(",", @elements) . ")";
    $vector =~ s/\'//g; # remove quotation marks from $vector
    #
    # example of output line, when using Weka NaiveBayes:
    #
    # "    inst#     actual  predicted error prediction"
    # "        1        2:1        1:0   +   1 (5887,smallness#n#1,|smallness|,0.9)"
    # "        8        2:1        2:1       0.843 (5735,port#a#1,|port|,0.5)"
    #
    # - predict the later frequency randomly
    #
    $instance_num++;
    #
    my $actual = "";
    if ($class == 1) {
      $actual = "2:1";
    } else {
      $actual = "1:0";
    }
    my $random = rand(1.0);
    my $predicted = "";
    my $error = "";
    my $prediction = "";
    if ($random >= 0.5) { # guess class 2:1
      $predicted = "2:1";
      if ($actual eq "2:1") {
        $error = "";
      } else {
        $error = "+";
      }
      $prediction = $random;
    } else { # guess class 1:0
      $predicted = "1:0";
      if ($actual eq "1:0") {
        $error = "";
      } else {
        $error = "+";
      }
      $prediction = 1.0 - $random; # flip probability
    }
    #
    # - output prediction in same format as Weka IBk
    # - use a relatively high number of decimals ("%.6f") to avoid ties
    #
    print $out_file sprintf("%9d   ", $instance_num) . # inst#
                    sprintf("%6s   ", $actual) . # actual
                    sprintf("%6s   ", $predicted) . # predicted
                    sprintf("%3s   ", $error) . # error
                    sprintf("%.6f  ", $prediction) . # prediction
                    $vector . "\n"; # (5735,leaseholder#n#1,0.011305,1,1.833333,2,0)
    #
  }
  #
  close $in_file;
  close $out_file;
  #
  print "... done reading $in_test_file_name and writing $out_results_file_name.\n";
  #
}
#