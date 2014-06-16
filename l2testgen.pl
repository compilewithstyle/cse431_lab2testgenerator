#!/usr/bin/perl

use strict;
use warnings;

=for comment

	Author: Nicholas Siow
	
	l2testgen.pl: Generates randomized tests for lab2, CSE431s, Spring 2014	

=cut

#------------------------------------------------------------------------------
#	determine test parameters
#------------------------------------------------------------------------------

my $max_items = 50;
my $max_list_size = 10;
my $max_literal_value = 50;
my $nesting_ratio = 0.5;
my $include_bad = 0;

foreach( @ARGV ) {
	if( $_ =~ /max_items=(\d+)/ ) {
		$max_items = $1;
	}
	if( $_ =~ /max_list_size=(\d+)/ ) {
		$max_list_size = $1;
	}
	if( $_ =~ /max_literal_value=(\d+)/ ) {
		$max_literal_value = $1;
	}
	if( $_ =~ /nesting_ratio=(\d+\.?\d*)/ ) {
		$nesting_ratio = $1;
	}
	if( $_ =~ /\-\-bad/ ) {
		$include_bad = 1;
	}
}

my %operations = (
	negate	=>	1,
	plus	=>	2,
	minus	=>	2,
	times	=>	2,
	sum	=>	'list',
	product	=>	'list',
	mean	=>	'list',
);

#------------------------------------------------------------------------------
# returns an array of atomic items, no nesting yet!
#------------------------------------------------------------------------------
sub get_items {
	my @items;
	my $number_of_items = int(rand($max_items))+1;
	foreach(1 .. $number_of_items) {

		my @possible_ops = keys %operations;
		my $op = $possible_ops[int(rand(7))];

		if( $operations{$op} eq 1 ) {
			my @values;
			push @values, int(rand($max_literal_value));
			push @items, '( ' . $op	. ' ' . "@values" . ' )';
		}	
		elsif( $operations{$op} eq 2 ) {
			my @values;
			push @values, int(rand($max_literal_value)) foreach 1..2;
			push @items, '( ' . $op	. ' ' . "@values" . ' )';
		}
		elsif( $operations{$op} eq 'list' ) {
			my @values;
			push @values, int(rand($max_literal_value)) foreach 1..int(rand($max_list_size))+1;
			push @items, '( ' . $op	. ' ' . "@values" . ' )';
		}
	}
	return @items;
}

#------------------------------------------------------------------------------
# takes an array of items starts replacing literals with other items,
# making longer and more complex nested items
#------------------------------------------------------------------------------
sub nest_items {

	my @items = @_;
	my @nested_tests;
	while(@items) {

		my $item = pop @items;
		( my @literals ) = $item =~ /(\d+)/g;
		my $number_of_nests = int(scalar(@literals) * $nesting_ratio);

		foreach( 1..$number_of_nests ) {
			last if scalar @items == 0;
			my $to_replace = $literals[rand @literals];
			my $replace_with = pop @items;

			# need spaces here or partial-numbers will be replaced!
			$item =~ s{ $to_replace }{ $replace_with };

			# refresh literal list for possible recursive nesting
			( @literals ) = $item =~ /(\d+)/g;
		}

		push @nested_tests, $item;
	}

	return @nested_tests;
}

#------------------------------------------------------------------------------
# takes in a nested item and repeatedly calls solve_item until the item is
# completely solved
#	PS - THIS IS REALLY COOL LOOK AT THE REGEX MAGIC
#------------------------------------------------------------------------------
sub solve_nested_item {

	my @nested_items = @_;
	my %solved_items;
	foreach my $item( @nested_items ) {
		my $orig = $item;
		# if item is marked as bad, go ahead and return bad
		if( $item =~ /b/ ) {
			$item =~ s{b}{}g;
			$solved_items{$item} = "bad";
			next;
		}
		# pull out a non-nested item and solve it
		while( $item =~ /( \( [^(^)]+ \) )/x) {
			my $inner = $1;
			my $solve = solve_item($inner);
			$item =~ s{\Q$inner\E}{$solve};
		}
		$solved_items{$orig} = $item;
	}

	return %solved_items;
}

#------------------------------------------------------------------------------
# takes a single atomic item with no nests, determines the operation being performed,
# and solves it out to a literal
#------------------------------------------------------------------------------
sub solve_item {

	my $item = shift;

	# sanitize in case minus sign got escaped
	$item =~ s{\/}{}g;
	$item =~ s{\\}{}g;

	if( $item =~ /\(\s*negate\s+(-?\d+)\s*\)/ ) {
		return -1 * $1;
	}
	elsif( $item =~ /\(\s*plus\s+(-?\d+)\s+(-?\d+)\s*\)/ ) {
		return $1 + $2;
	}
	elsif( $item =~ /\(\s*minus\s+(-?\d+)\s+(-?\d+)\s*\)/ ) {
		return $1 - $2;
	}
	elsif( $item =~ /\(\s*times\s+(-?\d+)\s+(-?\d+)\s*\)/ ) {
		return $1 * $2;
	}
	elsif( $item =~ /\(\s*sum\s+-?\d+.*\s*\)/ ) {
		( my @things2add ) = $item =~ /(-?\d+)/g;
		my $sum = 0;
		$sum += $_ foreach @things2add;
		return $sum;
	}
	elsif( $item =~ /\(\s*product\s+-?\d+.*\s*\)/ ) {
		( my @things2mult ) = $item =~ /(-?\d+)/g;
		my $prod = 1;
		$prod *= $_ foreach @things2mult;
		return $prod;
	}
	elsif( $item =~ /\(\s*mean\s+-?\d+.*\s*\)/ ) {
		( my @things2add ) = $item =~ /(-?\d+)/g;
		my $sum = 0;
		$sum += $_ foreach @things2add;
		# GET YOUR DIRTY FLOAT VALUES OUT OF HERE
		return int($sum / scalar(@things2add));
	}
}

#------------------------------------------------------------------------------
# if user indicated bad items to be included, add them here
#------------------------------------------------------------------------------
sub add_bad {

	if( scalar @_ < 5 ) {
		print "\n\tToo few values to insert bad ones. Try running again.\n\n";
		exit;
	}

	my @items = @_;
	my $rand_index = int(rand(scalar @items));
	my @bad_indices;

	# remove literals from one of the item entries
	# while loop to make sure script doesn't try to make the same
	# index bad twice
	while( $rand_index ~~ @bad_indices) {
		$rand_index = int(rand(scalar @items));
	}
	push @bad_indices, $rand_index;
	my $bad1 = $items[$rand_index];
	$bad1 =~ s{\d+}{}g;
	$bad1 = 'b' . $bad1;
	$items[$rand_index] = $bad1;

	# maybe give a list of values for an operation not expecting it
	$rand_index = int(rand(scalar @items));
	while( $rand_index ~~ @bad_indices) {
		$rand_index = int(rand(scalar @items));
	}
	my $bad2 = $items[$rand_index];
	( my $op ) = $bad2 =~ /([a-z]+)/;

	if( $operations{$op} ne 'list' ) {
		my @replacement_values;
		push @replacement_values, $_ foreach 1..5;

		( my $literal2replace ) = $bad2 =~ /(\d+)/;

		my $replace_string = "@replacement_values";
		$bad2 =~ s{$literal2replace}{$replace_string};
		$bad2 = 'b' . $bad2;
		$items[$rand_index] = $bad2;
	}

	# replace a 'list' operation with a 1/2 argument operation	
	$rand_index = int(rand(scalar @items));
	while( $rand_index ~~ @bad_indices) {
		$rand_index = int(rand(scalar @items));
	}
	my $bad3 = $items[$rand_index];
	( my $old_operation ) = $bad3 =~ /([a-z]+)/;

	if( $operations{$op} eq 'list' ) {
		# find a non-list-accepting replacement operation
		my $replacement_operation = int(rand(5));
		$bad3 =~ s{$op}{$replacement_operation};
		$bad3 = 'b' . $bad3;
		$items[$rand_index] = $bad3;
	}

	# clean up the huge whitespaces from insertions of the bad
	foreach(@items) {
		$_ =~ s{\s+}{ }g;
	}

	return @items;
}

#------------------------------------------------------------------------------
# makes the magic happen
#------------------------------------------------------------------------------
sub _main_ {

	my @items = get_items();

	@items = add_bad(@items) if $include_bad;

	my @nested_items = nest_items(@items);

	my %solved_items = solve_nested_item(@nested_items);

	print "\n" . "-"x75 . "\n";
	my $output = 0;
	while( my($t,$s) = each %solved_items ) {
		# go ahead and print if bad value
		printf( "%s ::: (* %s *)\n", $t, $s ) if $s eq "bad";
		# skip the huge-ass numbers
		next if $s =~ /e/;
		# and let's keep it within the range of 32-bit integers
		next if $s gt 2147483647;
		printf( "%s\t(* %s *)\n", $t, $s );
		$output = 1;
	}
	print "\n\tResults not displayed because they were HUUUUUUUUUUGUEUGEUUUEGU.\n\n" if $output == 0;
	print "-"x75 . "\n\n";
}

_main_();
