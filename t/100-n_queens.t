#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::N_Queens;

foreach my $size (1 .. 16) {
    subtest "$size Queens problem" => sub {
        my $generator = Regexp::N_Queens:: -> new -> init (size => $size);
        ok $generator, "Generator object" or return;
        my $subject =  $generator    -> subject;
        ok $subject => "Got subject" or return;
        my $pattern =  $generator    -> pattern;
        ok $pattern => "Got pattern" or return;
        my $matched =  $subject =~ $pattern;
        my %plus    =  %+;
        if ($size == 2 || $size == 3) {
            ok !$matched, "No solution";
            return;
        }
        ok $matched, "There is a solution";
        #
        # Find the squares with queens
        #
        my @positions;
        foreach my $x (1 .. $size) {
            foreach my $y (1 .. $size) {
                my $key = "Q_${x}_${y}";
                if ($plus {$key}) {
                    push @positions => [$x, $y];
                }
            }
        }
        is scalar @positions, $size, "Got $size Queens";
        subtest "All captures are 'Q'" => sub {
            foreach my $position (@positions) {
                my ($x, $y) = @$position;
                my $key = "Q_${x}_${y}";
                is $plus {$key}, "Q", "Capture '$key' equals 'Q'";
            }
        };
        if (@positions > 1) {
            subtest "Queens do not attack" => sub {
                for (my $i = 0; $i < @positions; $i ++) {
                    my ($x1, $y1) = @{$positions [$i]};
                    for (my $j = $i + 1; $j < @positions; $j ++) {
                        my ($x2, $y2) = @{$positions [$j]};
                        subtest "Queens on ($x1, $y1) and " .
                                          "($x2, $y2) do not attack" => sub {
                            ok $x1       != $x2,
                               "Queens are on different ranks";
                            ok $y1       != $y2,
                              "Queens are on different files";
                            ok $x1 - $x2 != $y1 - $y2,
                              "Queens are on different diagonals";
                            ok $x1 - $x2 != $y2 - $y1,
                              "Queens are on different anti-diagonals";
                        }
                    }
                }
            };
        }
    }
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
