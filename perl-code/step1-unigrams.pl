#
# step1-unigrams.pl
#
# - read the Google 1gram files and extract those
#   1grams that correspond to words in WordNet 3.0
#
# Peter Turney
# October 1, 2018
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
  if ($word !~ /_/) { push(@words, $word . "_NOUN") }; 
}
foreach $word (@verbs) { 
  if (length($word) < $min_length) { next; }
  if ($word !~ /_/) { push(@words, $word . "_VERB") }; 
}
foreach $word (@adjs) { 
  if (length($word) < $min_length) { next; }
  if ($word !~ /_/) { push(@words, $word . "_ADJ") }; 
}
foreach $word (@advs) { 
  if (length($word) < $min_length) { next; }
  if ($word !~ /_/) { push(@words, $word . "_ADV") }; 
}
#
# list of files for Google 1grams
#
my $google_dir = "../google-ngrams";
#
my @google_files = ();
my $alphabet = "abcdefghijklmnopqrstuvwxyz";
my $file_prefix = "googlebooks-eng-all-1gram-20120701-";
#
while ($alphabet =~ /(\w)/g) {
  push(@google_files, $google_dir . "/" . $file_prefix . $1);
}
#
# scan through the Google 1grams and write out all entries
# that match WordNet words
#
# - output file for yearly frequencies for WordNet unigrams
#
my $freq_file_name = "../perl-output/step1-unigrams.txt";
#
# - output file for earliest dates for WordNet unigrams
#
my $birth_file_name = "../perl-output/step1-birthdays.txt";
#
# - hash table of WordNet unigrams
#
my %wordnet_hash = ();
foreach $word (@words) {
  $wordnet_hash{$word} = 1;
}
#
# - scan through the Google 1gram files
#
print "writing to $freq_file_name and $birth_file_name ...\n";
#
open(my $freq_file, ">", $freq_file_name) or die "Could not open file: $freq_file_name\n";
open(my $birth_file, ">", $birth_file_name) or die "Could not open file: $birth_file_name\n";
#
my %new_word_hash = ();
#
foreach my $in_file_name (@google_files) {
  #
  print "reading: $in_file_name\n";
  #
  open(my $in_file, "<", $in_file_name) or die "Could not open file: $in_file_name\n";
  #
  while (my $line = <$in_file>) {
    chop($line);
    my ($unigram, $year, $num_occurrences, $num_books) = split(/\t/, $line);
    #
    # - is this word in WordNet?
    #
    if (defined($wordnet_hash{$unigram})) {
      #
      # - write unigram to frequency file
      #
      print $freq_file "$unigram\t$year\t$num_occurrences\n";
      #
      # - if this is a new word, write out the birth year and 
      #   show progress to the user
      #
      if (! defined($new_word_hash{$unigram})) {
        print $birth_file "$unigram\t$year\n";
        print "processing: $unigram - $year\n";
        $new_word_hash{$unigram} = 1;
      }
    }
  }
  close $in_file;
}
#
close $freq_file;
close $birth_file;
#
print "... done writing to $freq_file_name and $birth_file_name.\n";
#
