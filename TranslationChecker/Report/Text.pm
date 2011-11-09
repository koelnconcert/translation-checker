#!/usr/bin/perl
package TranslationChecker::Report::Text;
use strict;
use warnings;
use feature qw(say);
use Data::Dumper;
use TranslationChecker::Report;

sub format {
  my ($report) = @_;
 
  say $report->{orig_filename};
  say $report->{trans_filename};
 
  my $groups = TranslationChecker::Report::group_by_status($report); 

  for my $status (sort keys %$groups) {
    my $messages = $groups->{$status};
    my @messages = sort { $a->{key} cmp $b->{key} } @$messages;
    say "\n$status (".scalar(@messages).")";
    for my $message (@messages) {
      say $message->{key};
    }
  }
}

1;
