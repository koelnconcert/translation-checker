#!/usr/bin/perl
package TranslationChecker::Report::HTML;
use strict;
use warnings;
use feature qw(say);
use Data::Dumper;
use HTML::Entities;
use List::Util qw(sum);

sub format {
  my (@reports) = @_;

  say join "\n",
    wrap("html", undef, 
      wrap("head", undef,
        q{<link rel="stylesheet" type="text/css" href="report.css"/>},
        q{<script type="text/javascript" src="http://code.jquery.com/jquery-1.7.min.js"></script>},
      ),
      wrap("body", undef,
        wrap("div", "report",
          wrap("h1", undef, "Language-Report"),
          wrap("div", "stats",
            wrap("h2", undef, "Overview"),
            wrap("table", "stats",
              format_stats(@reports)
            ),
          ),
          wrap("div", "files",
            wrap("h2", undef, "Files"),
            q{<a href="#" onclick="$('div.message.current').toggle(); return false">Toggle all/non-current messages</a>},
            map({format_file($_)} @reports)
          )
        )
      )
    );
}

sub format_stats {
  my (@reports) = @_;
  my $total_report = TranslationChecker::Report::congregate_reports(@reports);
  my @columns = qw{file/lang percentages missing outdated orphaned current};
  return 
    wrap("tr", undef, map { wrap("th", undef, $_) } @columns),
    wrap("tr", "total", format_stat("total ($total_report->{lang})", $total_report)),
    (map { wrap("tr", undef, format_stat($_->{trans_filename}, $_)) } @reports);
}

sub format_stat {
  my ($title, $report) = @_;
  my $count = TranslationChecker::Report::count_by_status($report);
  my @status = qw/missing outdated orphaned current/;
  return 
    wrap("td", "filename", $title),
    wrap("td", "graph", format_graph($count)),
    (map { wrap("td", "status $_", $count->{$_}) } @status);
}

sub format_graph {
  my ($count) = @_;
  my @status = qw/missing outdated orphaned current/;
  my $sum = sum values %$count;

  return "division by zero" if $sum == 0;
  my %percentages = map { $_ => 100 * $count->{$_} / $sum } @status;

  return
    wrap("div", "graph",
      map { qq[<span class="status $_" title="$_" style="width:$percentages{$_}%">&nbsp;</span>] } @status
    );
}

sub format_file {
  my ($report) = @_;
 
  my $messages = $report->{messages}; 
  my @messages = sort { $a->{key} cmp $b->{key} } @$messages; 

  wrap("div", "file",
    wrap("div", "info",
      make_span("lang", $report),
      make_span("orig_filename", $report),
      make_span("trans_filename", $report)
    ),
    wrap("div", "messages",
      map({ format_message($_) } @messages)
    )
  );
}

sub format_message {
  my ($message) = @_;
  wrap("div", "message $message->{status}", 
     make_span("status", $message, "status $message->{status}"),
     make_span("key", $message),
     wrap("span", "orig",
       make_span("orig", $message, "orig_cur"),
       make_span("orig_old", $message)
     ),
     make_span("trans", $message)
  );
}

sub make_span {
  my ($key, $hash, $class) = @_;
  my $val = $hash->{$key} || "";
  wrap("span", $class || $key, encode_entities($val));
}

sub wrap {
  my ($element, $class, @content) = @_;
  my $attr = defined $class ? qq{ class="$class"} : "";
  my $start = qq{<$element$attr>};
  my $end = qq{</$element>};
  if ($element eq "span") {
    return join "", $start,@content,$end;
  } else {
    @content = map { "  $_" } @content;
    return $start,@content,$end;
  }
}

1;
