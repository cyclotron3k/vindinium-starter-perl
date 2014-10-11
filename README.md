vindinium-starter-perl
======================

Perl starter bot for [Vindinium](http://vindinium.org)

## Usage


```Perl
use Vindinium;

my $x = Vindinium->new(
    key => '????????',
    bot_name => 'Nurdle', # optional
    training => 1,        # optional, defaults to 0
    turns => 50           # optional, for training mode only
);

$x->print_board;  # prints the current playing board
                  # (starts a new game if one doesn't already exist)
$x->print_heroes; # prints a summary of the heroes

while ($x->in_progress)
{
  if ($x->game->{hero}{life} <= 30)
  {
    # move_to_nearest() takes a regex. Moves your player towards the nearest match
    $x->move_to_nearest(qr/\[\]/);
  }
  else
  {
    my $id = $x->game->{hero}{id};
    $x->move_to_nearest(qr/\$[^$id]/);
  }

  # valid_directions() returns an array of directions you can move in
  # e.g.:
  # my @dirs = $x->valid_directions;
  # my ($move) = $dirs[int rand scalar @dirs];
  # say "\nMoving $move";
  # $x->move($move);

  print "\n\n";
  $x->print_board;
  print "\n";
  $x->print_heroes;
  print "-" x 16;
  print "\n\n";

}
```
