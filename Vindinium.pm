package Vindinium;

use strict;
use warnings;
use 5.018;

use Moose;

use JSON;
use LWP::UserAgent;

our $VERSION = 0.01;

has 'bot_name'  => (is => 'rw', isa => 'Str', default => 'vindinium-starter-perl');
has 'version'   => (is => 'ro', isa => 'Str', default => $VERSION);
has 'start_url' => (is => 'ro', isa => 'Str', lazy_build => 1);
has 'play_url'  => (is => 'rw', isa => 'Str');
has 'key'       => (is => 'rw', isa => 'Str', required => 1);
has '_ua'       => (is => 'ro', isa => 'LWP::UserAgent', lazy_build => 1);
has 'turns'     => (is => 'ro', isa => 'Int', default => 50);
has 'game'      => (is => 'rw', isa => 'HashRef', lazy_build => 1);
has 'board'     => (is => 'rw', isa => 'ArrayRef[ArrayRef]', lazy_build => 1, clearer => '_clear_board');
has 'training'  => (is => 'ro', isa => 'Bool', default => 0);

sub _build__ua
{
	my $self = shift;
	return LWP::UserAgent->new(
		timeout => 60,
		keep_alive => 1,
		agent => join "/", $self->bot_name, $self->version
	);
}

sub _build_start_url
{
	my $self = shift;
	if ($self->training)
	{
		return 'http://vindinium.org/api/training';
	}
	else
	{
		return 'http://vindinium.org/api/arena';
	}
}

sub _build_game
{
	my $self = shift;
	my $res = $self->_ua->post($self->start_url, {key => $self->key, turns => $self->turns});

	if ($res->is_success)
	{
		my $game = decode_json $res->decoded_content;
		$self->play_url($game->{playUrl});
		return $game;
	}
	else
	{
		say $res->content;
		die $res->status_line;
	}
}

sub _build_board
{
	my $self = shift;
	my $size = $self->game->{game}{board}{size} * 2;
	my $tiles = $self->game->{game}{board}{tiles};

	return [map { [ /(..)/g ] } ($tiles =~ /(.{$size})/g)];
}

sub move
{
	my $self = shift;
	my $dir = shift || 'Stay';

	my $res = $self->_ua->post($self->play_url, {key => $self->key, dir => $dir} );
	if ($res->is_success)
	{
		$self->_clear_board;
		my $game = decode_json $res->decoded_content;
		$self->game($game);
	}
	else
	{
		say $res->content;
		die $res->status_line;
	}
}

sub in_progress
{
	my $self = shift;
	my $game = $self->game;
	return 0 if $game->{game}{finished};
	return 0 if $game->{hero}{crashed};
	return 1;
}

sub print_board
{
	my $self = shift;
	my $hero = $self->game->{hero};
	my $id = '@' . $hero->{id};

	say for map { join '', map {$_ eq $id ? "\e[31m$id\e[0m" : $_} @$_ } @{$self->board};
}

sub print_heroes
{
	my $self = shift;
	for my $p (@{$self->game->{game}{heroes}})
	{
		say join ', ', map { $_ . ": " . $p->{$_} } qw(name life gold mineCount);
	}
}

sub valid_directions
{
	my $self = shift;
	my $hero = $self->game->{hero};
	my $x = $_[0] || $hero->{pos}{x};
	my $y = $_[1] || $hero->{pos}{y};
	my $id = '@' . $hero->{id};
	my $b = $self->board;

	my $s = $self->game->{game}{board}{size} - 1;

	my @valid = 'Stay';
	push @valid, 'North', if $x >= 0 and $b->[$x - 1][$y] ne '##';
	push @valid, 'South', if $x < $s and $b->[$x + 1][$y] ne '##';
	push @valid, 'East',  if $y < $s and $b->[$x][$y + 1] ne '##';
	push @valid, 'West',  if $y >= 0 and $b->[$x][$y - 1] ne '##';

	return @valid;
}

sub find
{
	my $self = shift;
	my $find = shift;
	my $b = $self->board;
	my $s = $self->game->{game}{board}{size};

	my @found = ();
	my $x = 0;
	while ($x < $s)
	{
		my $y = 0;
		while ($y < $s)
		{
			push @found, [$x, $y] if $b->[$x][$y] =~ $find;
			$y++;
		}
		$x++;
	}
	return @found;
}

sub move_to_nearest
{
	my $self = shift;
	$self->move($self->path_to_nearest($_[0]));
}

sub path_to_nearest
{
	my $self           = shift;
	my @targets        = $self->find($_[0]);
	my %targets        = ();
	my $hero           = $self->game->{hero};
	my $x              = $hero->{pos}{x};
	my $y              = $hero->{pos}{y};
	my $id             = '@' . $hero->{id};
	my @endpoints      = [$x, $y, undef];
	my %seen           = ();
	my $b              = $self->board;
	my $found;

	for my $t (@targets)
	{
		$targets{$t->[0]}{$t->[1]} = 1;
	}

	my %vdm = (
		North => [-1,  0],
		South => [ 1,  0],
		East  => [ 0,  1],
		West  => [ 0, -1]
	);

	my $e;
	while (!defined $found and $e = shift @endpoints)
	{
		my $cell = $b->[$e->[0]][$e->[1]];
		
		if (defined $targets{$e->[0]} and defined $targets{$e->[0]}{$e->[1]})
		{
			$found = $seen{$e->[0]}{$e->[1]} = $e->[2];
			last;
		}
		elsif (defined $seen{$e->[0]} and defined $seen{$e->[0]}{$e->[1]})
		{
			next;
		}
		elsif ($cell ne '  ' and $cell ne $id)
		{
			next;
		}
		else
		{
			$seen{$e->[0]}{$e->[1]} = $e->[2];
			push @endpoints,
				map {
					[
						$e->[0] + $vdm{$_}[0],
						$e->[1] + $vdm{$_}[1],
						{
							prev => $seen{$e->[0]}{$e->[1]},
							dir => $_
						}
					]
				}
				grep {
					defined $vdm{$_}
				} $self->valid_directions($e->[0], $e->[1]);
		}
	}

	return unless $found;

	my @route = ();
	do { unshift @route, $found->{dir}; } while $found = $found->{prev};

	return @route;
}

sub mines
{
	my $self = shift;
	return $self->find(qr/^\$.$/);
}

sub taverns
{
	my $self = shift;
	return $self->find(qr/^\[\]$/);
}

1;

