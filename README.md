# natural-selection-of-words
This repository contains the software used in the paper 
The Natural Selection of Words: Finding the Features of Fitness. 


README - Peter Turney, January 10, 2019
---------------------------------------

See the paper The Natural Selection of Words: Finding the 
Features of Fitness for a detailed description of the steps
in the algorithm.

Here is a brief description of the subdirectories in this folder:

- catvar: Categorial Variations 2.1
- google-ngrams: Google Ngram files for unigrams (single words)
- perl-code: the Perl code that runs the experiments
- perl-output: the output text files of the Perl code

Here are the steps required to install the files and tools. 
The code was written for Windows 10, but it should also work with 
Linux and MacOS with some minor modifications.

(1) Install Strawberry Perl for Windows 10

- http://strawberryperl.com/
- we used perl 5, version 26, subversion 1 (v5.26.1) 

(2) Install WordNet 3.0

- https://wordnet.princeton.edu/download
- we used WordNet version 3.0 for compatability with WordNet::QueryData
- install WordNet 3.0 in the directory "C:\Program Files\WordNet\3.0"
- any other location will make it difficult to use WordNet::QueryData
- WordNet 3.1 has not been fully tested with WordNet::QueryData

(3) Install WordNet::QueryData 1.49

- https://metacpan.org/pod/WordNet::QueryData
- run the command "cpan  WordNet::QueryData" to install WordNet::QueryData
- "cpan" is included in Strawberry Perl
- "cpan" will automatically download the required files from the web
- we used WordNet::QueryData version 1.49

(4) Install Lingua::EN::Syllable 0.30

- https://metacpan.org/release/Lingua-EN-Syllable
- run the command "cpan Lingua::EN::Syllable" to install Lingua::EN::Syllable
- "cpan" will automatically download the required files from the web
- we used Lingua::EN::Syllable version 0.30

(5) Install Weka 3.8.2

- https://www.cs.waikato.ac.nz/~ml/weka/downloading.html
- we used Weka version 3.8.2

(6) Install Categorial Variations 2.1

- https://clipdemos.umiacs.umd.edu/catvar/
- read the file "README-PDT.txt" in the directory /catvar/
- download the required CatVar files and put them in /catvar/
- go to the directory /perl-code/ and run the Perl script "wordnet-catvar.pl"
- in Windows, use the command "perl wordnet-catvar.pl"
  
(7) Install Google Ngram files

- http://storage.googleapis.com/books/ngrams/books/datasetsv2.html
- read the file "README-PDT.txt" in the directory /google-ngrams/
- download the required files and put them in /google-ngrams/

(8) Run the Perl scripts

- go to the directory /perl-code/
- the command "perl doit.pl" will run all seven steps of the algorithm
- "doit.pl" does not take any command line arguments
- the behaviour of "doit.pl" is controlled by the file "configuration.txt"
- you can modify the behaviour of "doit.pl" by commenting out code
  or changing the contents of "configuration.txt"


