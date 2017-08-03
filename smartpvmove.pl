#!/usr/bin/perl

use strict;
use warnings;

if ($#ARGV < 1) {
    usage();
    exit;
}

my @commands;

my ($device_from, $from, $end_from) = $ARGV[0] =~ /(.+):([^-]+)-(\d+)/;
my ($device_to, $to, $end_to) = $ARGV[1] =~ /([^:]+):(\d+)-?(\d*)/;
my $count = $end_from - $from + 1;
my $chunk = $ARGV[2];
$end_to = $to + $count - 1 unless $end_to;
my $shift = $to - $from;
unless ($chunk) {
    print "Chunk size is not given.\n";
    $chunk = $count + 1;
}
if ($chunk > $count) {
    my $abs_shift = abs($shift);
    $chunk = $count > $abs_shift ? $abs_shift : $count;
    print "Chunk size set to $chunk extents.\n";
}

printf <<VALUES, $device_from, $from, $device_to, $to, $count, $chunk;
Values:
from device "%s" at extent %d
to device "%s" at extent %d
extents %d (for %d in chunk)

VALUES

die "Разное количество экстентов" if $count != $end_to - $to + 1;

my $position;
if ($shift < 0) {
    $position = $from;
}
else {
    $position = $from + $count - $chunk;
}


while ($count) {
    if ($chunk > $count) {
        $chunk = $count;
    }
    push @commands, sprintf "pvmove --alloc anywhere %s:%d-%d %s:%d-%d", $device_from, $position, $position + $chunk - 1, $device_to, $position + $shift, $position + $shift + $chunk - 1;
    $count -= $chunk;
    if ($shift < 0) {
        $position += $chunk;
    }
    else {
        $position -= $chunk;
    }
}

print_commands();

print "Continue? (y[es]|n[o])\n";

if (<STDIN> =~ /^\s*[yY]e?s?\s*$/) {
    exec_commands();
}

sub print_commands {
    print "Will executed:\n";
    print join("\n", @commands);
    print "\n";
}

sub exec_commands {
    # print "Это всё будет выполнено\n";
    # exit;
    foreach (@commands) {
        print "$_\n";
        die "Ошибка выполнения команды \"$_\"" if system($_);
    }
}

sub usage {
    print <<END
$0 <device>:<first>-<last> <device>:<first>-<last> [<chunk>]

END
}
