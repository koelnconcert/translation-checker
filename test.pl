#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use TranslationChecker::Report;
use TranslationChecker::Report::HTML;
use TranslationChecker::Report::Text;
use Data::Dumper;
use File::Glob ':glob';
use Sysadm::Install qw(blurt);

sub get_available_languages {
  my (@files) = @_;
  @files = map { s/(\.properties$)/_\*$1/; $_ } @files;
  @files = map { bsd_glob($_) } @files;
  @files = map { s/.*_(\w+)\.properties$/$1/; $_ } @files;
  my %files = map { $_ => 1 } @files;
  @files = keys %files;
}

sub write_reports {
  my ($outdir, @files) = @_;
  my @lang = get_available_languages(@files);

#  my %reports;
  for my $lang (@lang) {
    say STDERR "generating report for $lang";

    my @reports = map { TranslationChecker::Report::generate($_, $lang) } @files;
    my $html = TranslationChecker::Report::HTML::format(@reports);
    
    my $file = "$outdir/report_$lang.html";
    blurt($html, $file);
    
    #$reports{$lang} = \@reports;
  }
}

sub main {
  my @files = @ARGV;
  my $outdir = "/home/peterss/tmp/translation/html";

  write_reports($outdir, @files);
}

main();
