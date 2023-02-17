package Regexp::N_Queens;

use 5.028;
use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

use Hash::Util::FieldHash qw [fieldhash];

use lib qw [lib];

our $VERSION = '2023021601';

fieldhash my %size;
fieldhash my %pattern;
fieldhash my %subject;

my $queen  = "Q";
my $prefix = "Q";

sub new ($class) {bless \do {my $v => $class}}
sub init ($self, @args) {
    my $args = @args == 1 && ref $args [0] eq "HASH" ? $args [0] : {@args};

    $self -> init_size ($args);

    if (keys %$args) {
        die "Unknown parameter(s) to init: " . join (", " => keys %$args)
                                             . "\n";
    }

    $self;
}

sub init_size ($self, $args) {
    $size {$self} = delete $$args {size} || 8;
    $self;
}
sub size ($self) {
    $size {$self}
}


sub subject ($self) {
    $self -> init_subject_and_pattern;
    $subject {$self};
}
sub pattern ($self) {
    $self -> init_subject_and_pattern;
    $pattern {$self};
}

my sub name ($square) {
    join "_" => $prefix, @$square
}
my sub coordinates ($name)  {
    if ($name =~ /^${prefix}_([0-9]+)_([0-9]+)/) {
        return [$1, $2];
    }
    return;
}
my $X = 0;
my $Y = 1;
my sub attacks ($sq1, $sq2) {
                 $$sq1 [$X] == $$sq2 [$X]              || # Same column
                 $$sq1 [$Y] == $$sq2 [$Y]              || # Same row
    $$sq1 [$X] - $$sq2 [$X] == $$sq1 [$Y] - $$sq2 [$Y] || # Same diagonal
    $$sq1 [$X] - $$sq2 [$X] == $$sq2 [$Y] - $$sq1 [$Y]    # Same anti-diagonal
}

sub init_subject_and_pattern ($self) {
    return if $subject {$self} && $pattern {$self};

    my $subject = "";
    my $pattern = "";
    my $size    = $self -> size;

    #
    # Process each of the squares
    #
    my @previous_squares;
    foreach my $x (1 .. $size) {
        foreach my $y (1 .. $size) {
            my $this_square = [$x, $y];
            #
            # First, decide whether the square gets a Queen or not.
            # We capture this in a capture group ("Q_$x_$y"). If
            # we capture a 'Q', there is a Queen on the square, else
            # there is no Queen on the square.
            #
            my $this_group = name $this_square;
            $subject .= "$queen;";
            $pattern .= "(?<$this_group>$queen?)$queen?;";

            #
            # Now we compare this cell with each of the previous squares.
            # If they are a Queens move away (they can attack each other
            # if both of them have a Queen), the two squares may have at
            # most one Queen among them.
            #
            foreach my $previous_square (@previous_squares) {
                next unless attacks $this_square, $previous_square;
                my $prev_group = name $previous_square;
                $subject .= "$queen;";
                $pattern .= "\\g{$prev_group}\\g{$this_group}$queen?;";
            }
            push @previous_squares => $this_square;
        }
    }

    #
    # Final condition: we placed the exact amount of Queens.
    #
    $subject .= ($queen x $size) . ";";
    $pattern .= join "" => map {my $group = name $_; "\\g{$group}"}
                           @previous_squares;
    $pattern .= ";";

    $subject {$self} =       $subject;
    $pattern {$self} = '^' . $pattern . '$';

    $self;
}


1;

__END__

=head1 NAME

Regexp::N_Queens - Abstract

=head1 SYNOPSIS

  use Regexp::N_Queens;

  my $N       = 8;
  my $solver  = Regexp::N_Queens:: -> new -> init (size => $N);
  my $subject = $solver -> subject;
  my $pattern = $solver -> pattern;
  if ($subject =~ $pattern) {
      foreach my $x (1 .. $N) {
          foreach my $y (1 .. $N) {
              print $+ {"Q_${x}_${y}"} ? "Q" : ".";
          }
          print "\n";
      }
  }
  else {
      say "No solution for an $N x $N board"
  }

=head1 DESCRIPTION

Solves the C<< N >>-Queens problem using a regular expression. The
C<< N >>-Queens problem asks you to place C<< N >> Queens on an 
C<< N x N >> chess board such that no two Queens attack each other.
There are solutions for each positive C<< N >>, except for C<< N == 2 >>
and C<< N == 3 >>.

After creating the solver object with C<< new >>, and initializing it
with C<< init >> (which takes a C<< size >> parameter indicating the size
of the board), the solver object can be queried by the methods
C<< subject >> and C<< pattern >>. Matching the pattern returned by
C<< pattern >> against the string returned by C<< subject >> solves the
C<< N >>-Queens problem: if there is a match, the Queens can be placed,
if there is no match, no solution exists.

If there is a match, the content of the board can be found in the
C<< %+ >> hash: for each square C<< (x, y) >> on the board, with
C<< 1 <= x, y <= N >>, we create a key C<< $key = "Q_${x}_${y}" >>.
We can now determine whether the field contain a Queen: if
C<< $+ {$key} >> is true, there is a Queen on the square, else, there
is no Queen.

Note that it doesn't matter in which corner of the board you place
the square C<< (1, 1) >>, nor which direction you give to C<< x >> and
C<< y >>, as each reflection and rotation of a solution to the
C<< N >>-Queens problem is also a solution.

=head1 BUGS

=head1 TODO

=over 2

=item * Perhaps sometime, write some tests.

=item * This isn't fast for larger C<< N >>. On the machine this module
was written on, it does sizes up to C<< 13 >> in less than 1 second,
sizes C<< 14 >> and C<< 15 >> in C<< 24 >> and C<< 29 >> seconds, and
size C<< 16 >> I killed after it didn't find a solution within C<< 5 >>
minutes, while the machine itself was trying to mimic the sound of a Concorde.

Some optimizations are possible.

=back

=head1 SEE ALSO

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Regexp-N_Queens.git >>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.freedom.nl >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2023 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
