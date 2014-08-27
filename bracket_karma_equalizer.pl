#!/usr/bin/env perl

use strict;
use warnings;

use vars qw($VERSION %IRSSI);
use Irssi qw(signal_add signal_emit signal_stop);

$VERSION = '0.10';
%IRSSI = (
  authors => 'Michael Stark',
  contact => 'stark3@gmail.com',
  name => 'Bracket Karma Equalizer',
  description => 'Prevent evil people from harming > or <s karma',
  license => 'None',
);

my $message_public = sub {
  my ($server, $msg, $nick, $address, $channel) = @_;
  return if !$server;
  my @words = split(' ', $msg);
  foreach my $word (@words) {
    if ($word =~ /(^(?:\+\+|--)*)((?:\(*[<>]\)*))((?:\+\+|--)*).*$/) {
      # There's a bracket with karma-modifying text around it...maybe. Need to
      # check if the parentheses around $bracket are balanced.
      # Also, oddly, karma_bot will recognize (text1)--(text2) and modify text1's
      # karma. So we ignore everything after the last ++ or -- since it won't
      # stop the bracket's karma from being affected.

      my ($pre, $bracket, $post) = ($1, $2, $3);
      while ($bracket =~ /\(.*\)/) {
        # Trim off one layer of parentheses.
        $bracket = substr($bracket, 1, length($bracket) - 2);
      }
      if ($bracket ne '>' and $bracket ne '<') {
        # Imbalanced parentheses. No need to balance.
        return;
      }

      my $newmsg = $bracket;
      if ($pre =~ /^(?:[+-]{2})+$/) {
        $pre =~ s/\+{2}//g;
        $pre =~ s/-{2}/\+\+/g;
        $newmsg = $pre . $newmsg;
      }

      if ($post =~ /^(?:[+-]{2})+$/) {
        $post =~ s/\+{2}//g;
        $post =~ s/-{2}/\+\+/g;
        $newmsg = $newmsg . $post;
      }

      if ($newmsg ne $bracket) {
        $server->command("msg $channel $newmsg");
      }
    }
  }
};

signal_add('message public', $message_public);
