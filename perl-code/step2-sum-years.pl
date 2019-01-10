#
# step2-sum-years.pl
#
# - read the WordNet unigram yearly frequencies and
#   calculate sums for selected years
#
# Peter Turney
# October 1, 2018
#
use strict;
use warnings;
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
my @period_names = ();
my %period_start = ();
my %period_stop = ();
#
open(my $config_file, "<", $config_file_name) or die "Could not open file: $config_file_name\n";
#
while (my $line = <$config_file>) {
  chop($line);
  if ($line =~ /^\#/) { next; } # skip comment lines
  if ($line !~ /^\S+\s+\S+\s+\S+$/) { next; } # line must contain exactly three items
  my ($name, $start, $stop) = split(/\s+/, $line);
  push(@period_names, $name);
  $period_start{$name} = $start;
  $period_stop{$name} = $stop;
}
#
close $config_file;
#
# print to standard output for verification
#
foreach my $period_name (@period_names) {
  my $start = $period_start{$period_name};
  my $stop = $period_stop{$period_name};
  print "period $period_name: $start - $stop\n";
}
# 
# read in the year-by-year data and calculate sums
#
my $in_file_name = "../perl-output/step1-unigrams.txt";
#
my %word_hash = ();
my %word_period_sum = ();
#
open(my $in_file, "<", $in_file_name) or die "Could not open file: $in_file_name\n";
#
print "reading $in_file_name ...\n";
#
while (my $line = <$in_file>) {
  chop($line);
  # example of $line: 
  #   "endow_VERB 1992 6303" 
  #   "word_part-of-speech year frequency"
  my ($word, $year, $num_occurrences) = split(/\t/, $line);
  # require words to be purely alphabetic
  # - no hyphens, periods, apostrophes, etc.
  if ($word !~ /^[a-z]+\_[A-Z]+$/) { next; } 
  foreach my $period_name (@period_names) {
    my $start = $period_start{$period_name};
    my $stop = $period_stop{$period_name};
    if (($year >= $start) && ($year <= $stop)) {
      $word_period_sum{"$word $period_name"} += $num_occurrences;
      $word_hash{$word} = 1;
    }
  }
}
#
print "... done reading $in_file_name.\n";
#
close $in_file;
#
# write out the sums
#
my $out_file_name = "../perl-output/step2-sum-years.txt";
#
open(my $out_file, ">", $out_file_name) or die "Could not open file: $out_file_name\n";
#
print "writing $out_file_name ...\n";
#
my @sorted_words = sort { $a cmp $b } (keys %word_hash);
#
foreach my $word (@sorted_words) {
  my @sums = ();
  foreach my $period_name (@period_names) {
    if (defined($word_period_sum{"$word $period_name"})) {
      push(@sums, $word_period_sum{"$word $period_name"});
    } else {
      push(@sums, 0);
    }
  }
  print $out_file $word . "\t" . join("\t", @sums) . "\n";
}
#
print "... done writing $out_file_name.\n";
#
close $out_file;
#