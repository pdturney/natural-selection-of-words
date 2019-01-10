#
# step6-run-weka.pl
#
# - run Weka on the training and testing files
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
  my $in_train_file_name = "../perl-output/step5-$train-features.arff";
  my $in_test_file_name = "../perl-output/step5-$test-features.arff";
  #
  # output file
  #
  my $out_results_file_name = "../perl-output/step6-$train-$test-weka.txt";
  #
  # range of ARFF features to show in the results file
  #
  my $range = "first-last";
  #
  # command for executing Weka
  #
  my $command = 'java -Xms4096m -Xmx8192m ' . # memory
                '-classpath "C:\Program Files\Weka-3-8\weka.jar" ' . # Weka location
                'weka.classifiers.meta.FilteredClassifier ' . # filter to remove some columns
                '-t ' . $in_train_file_name . ' ' . # train
                '-T ' . $in_test_file_name . ' ' . # test
                '-p ' . $range . ' ' . # range of features/columns to show
                '-num-decimal-places 4 ' . # number of decimals to show
                '-F "weka.filters.unsupervised.attribute.Remove -R 1-2" ' . # hide columns
                '-S 1 ' . # random number seed
                '-W weka.classifiers.meta.FilteredClassifier -- ' .
                '-F "weka.filters.unsupervised.attribute.StringToWordVector ' . # extract letter ngrams
                '-R first-last -W 50000 -prune-rate -1.0 -N 0 ' .
                '-stemmer weka.core.stemmers.NullStemmer ' .
                '-stopwords-handler weka.core.stopwords.Null -M 1 ' .
                '-tokenizer \"weka.core.tokenizers.WordTokenizer \"" ' .
                '-S 1 ' .
                '-W weka.classifiers.bayes.NaiveBayes ' .
                '> ' . $out_results_file_name;
  #
  print "$command\n";
  #
  # run Weka
  #
  system($command);
  #
}
#