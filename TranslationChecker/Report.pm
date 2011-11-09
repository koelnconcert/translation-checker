#!/usr/bin/perl
package TranslationChecker::Report;
use strict;
use warnings;
use feature qw(say);
use Data::Dumper;
use Git::Wrapper;

sub generate {
  my ($orig_filename, $lang) = @_;
  my $trans_filename = build_trans_filename($orig_filename, $lang);
  my ($trans, $orig, $orig_old) = get_properties($trans_filename, $orig_filename);

  my %all = (%$orig, %$trans);
  my @keys = keys %all;
  my @list = map { make_record($trans, $orig, $orig_old, $_) } @keys; 

  my %report;

  $report{orig_filename} = $orig_filename;
  $report{trans_filename} = $trans_filename;
  $report{lang} = $lang;
  $report{messages} = \@list;

  return \%report;
}

sub group_by_status {
  my ($report) = @_;

  my $messages = $report->{messages}; 
  my %status = map { $_->{status} => 1 } @$messages;
  for my $status (keys %status) {
    my @list = grep { $_->{status} eq $status } @$messages;
    $status{$status} = \@list;
  }
 
  return \%status;
}

sub count_by_status {
  my ($report) = @_;
  my $messages = group_by_status($report);
  my @status = qw/missing outdated orphaned current/;
  my %count = map { my $group = $messages->{$_} || []; $_ => scalar @$group  } @status;
  return \%count;
}

sub congregate_reports {
  my (@reports) = @_;
  my @messages = map { @{$_->{messages}} } @reports;
  my $report = {
     orig_filename => join_hash_values("orig_filename", @reports),
     trans_filename => join_hash_values("trans_filename", @reports),
     lang => join_hash_values("lang", @reports),
     messages => \@messages
  };
  return $report; 
}

sub join_hash_values {
  my ($key, @hashes) = @_;
  my %values = map { $_->{$key} => 1} @hashes;
  return join " ", sort keys %values;
}

sub build_trans_filename {
  my ($filename, $lang) = @_;
  $filename =~ s/\.(.*?)$/_$lang.$1/;
  return $filename;
}

sub make_record {
  my ($trans, $orig, $orig_old, $key) = @_;
  my %hash;
  $hash{key} = $key;
  $hash{orig} = $orig->{$key};
  $hash{orig_old} = $orig_old->{$key};
  $hash{trans} = $trans->{$key};
  $hash{status} = get_status(\%hash);
  return \%hash;
}

sub get_status {
  my ($hash) = @_;
  if (not defined $hash->{orig}) { 
    return "orphaned"
  } elsif (not defined $hash->{trans}) {
    return "missing"
  } elsif ($hash->{orig} ne $hash->{orig_old}) {
    return "outdated"
  } else {
    return "current";
  }
}

sub get_properties {
  my ($trans_filename, $orig_filename) = @_;

  open (my $ORIG, $orig_filename) or die "$orig_filename: $!";
  my @ORIG = <$ORIG>;

  my @TRANS;
  if (open (my $TRANS, $trans_filename)) {
    @TRANS = <$TRANS>;
  }

  my @ORIG_OLD = get_old_revision($trans_filename, $orig_filename);

  my $orig = properties_to_hash(@ORIG);
  my $orig_old = properties_to_hash(@ORIG_OLD);
  my $trans = properties_to_hash(@TRANS);
  return ($trans, $orig, $orig_old);
}

sub get_old_revision {
  my ($trans_filename, $orig_filename) = @_;
  my $git = Git::Wrapper->new(".");
  my @revisions = $git->rev_list(qw/-n 1 HEAD --/, $trans_filename);
  $git->show("$revisions[0]:$orig_filename"); 
}

sub properties_to_hash {
  my %hash;
  for (@_) {
    chomp;
    my ($key, $val) = /^([^=]+?)\s*=\s*(.*?)\s*$/;
    $hash{$key} = $val if $key;
  }
  return \%hash;
}

1;
