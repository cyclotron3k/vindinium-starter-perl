use strict;
use warnings;
use 5.018;

use Data::Dumper;
use Vindinium;

my $x = Vindinium->new(key => '????????', bot_name => 'Nurdle');
# my $x = Vindinium->new(key => '????????', bot_name => 'Nurdle', training => 1, turns => 50);

$x->print_board;
$x->print_heroes;

while ($x->in_progress)
{
	if ($x->game->{hero}{life} <= 30)
	{
		$x->move_to_nearest(qr/\[\]/);
	}
	else
	{
		my $id = $x->game->{hero}{id};
		$x->move_to_nearest(qr/\$[^$id]/);
	}

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

# say Dumper $x->game;

