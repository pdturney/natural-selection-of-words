#
# doit.pl
#
# - run all the steps
#
# Peter Turney
# October 6, 2018
#
# - comment out steps that are not needed
#
# - choose the time periods desired
# - run only one or zero of these four copy commands
#
#system("copy /Y configuration-4periods.txt configuration.txt");
#system("copy /Y configuration-5periods.txt configuration.txt");
#system("copy /Y configuration-6periods.txt configuration.txt");
#system("copy /Y configuration-7periods.txt configuration.txt");
#
# - delete old files that are no longer needed
#
#system("del ..\\perl-output\\step1-*.txt");
#system("del ..\\perl-output\\step2-*.txt");
#system("del ..\\perl-output\\step3-*.txt");
#system("del ..\\perl-output\\step4-*.txt");
#system("del ..\\perl-output\\step5-*.arff");
#system("del ..\\perl-output\\step6-*.txt");
#system("del ..\\perl-output\\step7-*.txt");
#
# - run the desired steps
#
system("perl step1-unigrams.pl"); 
system("perl step2-sum-years.pl");
system("perl step3-get-cases.pl");
system("perl step4-split-cases.pl");
system("perl step5-make-features.pl");
system("perl step6-run-weka.pl");
system("perl step7-summarize.pl");
#
# - run random baselines
#
system("perl step6-random-baseline.pl");
system("perl step7-random-summarize.pl");
#