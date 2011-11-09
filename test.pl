#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);
use TranslationChecker::Report;
use TranslationChecker::Report::HTML;
use TranslationChecker::Report::Text;
use Data::Dumper;

my $lang = shift;
my @files = @ARGV;

my @reports = map { TranslationChecker::Report::generate($_, $lang) } @files;

TranslationChecker::Report::HTML::format(@reports);


