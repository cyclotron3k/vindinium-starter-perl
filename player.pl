use strict;
use warnings;
use 5.018;

use Data::Dumper;
use Vindinium;

# my $x = Vindinium->new(key => '????????', bot_name => 'Nurdle');
my $x = Vindinium->new(key => '????????', bot_name => 'Nurdle', training => 1, moves => 10);

$x->print_board;

while ($x->in_progress)
{
        if ($x->game->{hero}{life} <= 30)
        {
        	$x->move_to_nearest(qr/\[\]/);
        }
        else
        {
        	$x->move_to_nearest(qr/\$-/);
        }

        # my @dirs = $x->valid_directions;
		# my ($move) = $moves[int rand scalar @dirs];
        # say "\nMoving $move";
        # $x->move($move);

        $x->print_board;

        for my $p (@{$x->game->{game}{heroes}})
        {
        	say join ', ', map { $_ . ": " . $p->{$_} } qw(name life gold mineCount);
        }

}

# say Dumper $x->game;
