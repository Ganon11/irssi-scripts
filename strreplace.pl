#!/usr/bin/env perl

use strict;
use warnings;

use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind signal_add);
use IO::File;
$VERSION = '0.10';
%IRSSI = (
          authors => 'Michael Stark',
          contact => 'stark3@gmail.com',
          name => 'String Replace',
          description => 'Replace text with associated strings in your messages.',
          license => 'None',
);

my %replacement_words;

my $replace = sub {
    my ($msg, $server, $channel) = @_;
    my $flag = 0;
    foreach my $word (keys %replacement_words) {
        if ($msg =~ /\{$word\}/i) {
            $flag = 1;
        }
        $msg =~ s/\{$word\}/$replacement_words{$word}/ig;
    }
    return unless $flag == 1;
    Irssi::signal_emit("send text", $msg, $server, $channel);
    Irssi::signal_stop();
};

my $cmd_add = sub {
    my ($data, $server, $witem) = @_;
    my ($word1, $word2) = split(/:/, $data);
    print "Adding {$word1} = '$word2'...";
    $replacement_words{$word1} = $word2;
};

my $cmd_remove = sub {
    my ($data, $server, $witem) = @_;
    print "Removing '$data'...";
    if (defined $replacement_words{$data}) {
        delete $replacement_words{$data};
    }
};

my $io_fail = sub {
    my $errmsg = shift;
    print "Error: $errmsg";
    return;
};

my $cmd_save = sub {
    print "Saving words...";
    my ($data, $server, $witem) = @_;
    my $ofh;
    if (!$data) {
        open($ofh, ">replacements.txt") or return &$io_fail($!);
    } else {
        open($ofh, ">$data") or return io_fail($!);
    }
    my @lines;
    foreach my $word (keys %replacement_words) {
        push(@lines, "$word:$replacement_words{$word}");
    }
    print $ofh join("\n", @lines);
    close($ofh);
    print "Save complete.";
};

my $cmd_load = sub {
    print "Loading words...";
    my ($data, $server, $witem) = @_;
    %replacement_words = ();
    my $ifh;
    if (!$data) {
        open($ifh, "<replacements.txt") or return &$io_fail($!);
    } else {
        open($ifh, "<$data") or return io_fail($!);
    }
    while (<$ifh>)
    {
        my $line = $_;
        chomp($line);
        my ($word1, $word2) = split(/:/, $line);
        print "Found '$word1' = '$word2'";
        $replacement_words{$word1} = $word2;
    }
    close($ifh);
    print "Load complete.";
};

my $cmd_debug = sub {
    foreach my $word (keys %replacement_words) {
        print "'$word' -> '$replacement_words{$word}'";
    }
    print "Done.";
};

my $helpstring = <<END;
COMMANDS:
    STRADD word1:word2 - Adds a replacement of word1 to word2.
    STRREMOVE word - Removes the replacement association for word.
    STRSAVE [file] - Saves the list of associations to [file] or ~/replacements.txt if none specified.
    STRLOAD [file] - Loads a list of associations from [file] or ~/replacements.txt if none specified.
              Warning: this will clear your current list of associations!
    STRDEBUG - Prints the current list of associations.
    STRHELP - Prints this help message.

Written and maintained by Michael Stark (stark3\@gmail.com)
END

my $cmd_help = sub {
   print "$helpstring"; 
};

signal_add("send text", $replace);
command_bind("strload", $cmd_load);
command_bind("strsave", $cmd_save);
command_bind("stradd", $cmd_add);
command_bind("strremove", $cmd_remove);
command_bind("strdebug", $cmd_debug);
command_bind("strhelp", $cmd_help);

# Load on startup
&$cmd_load();
	
