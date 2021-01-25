#!/usr/bin/perl -w
use strict;

die "\n\tUsage: $0 mergeLink sameLUCA Size-res \n\n" unless @ARGV==3;

my (%Size,%Group);
open AA,"$ARGV[0]" or die $!;
while(<AA>){
	chomp;
	next if $.==1;
	my @arr=split;
	$Group{$arr[1]}=$arr[2];
	if (defined $Size{$arr[1]}){
		if ($arr[1]=~/LUCA/){
			$Size{$arr[1]} += 10;
		}else{
			$Size{$arr[1]} += 20;
		}
	}else{
		if ($arr[1]=~/LUCA/){
			$Size{$arr[1]} = 20;
		}else{
			$Size{$arr[1]} = 40;
		}
	}
}
close AA;
open BB,"$ARGV[1]" or die $!;
while(<BB>){
	chomp;
	next if $.==1;
	my @arr=split;
	$Size{$arr[0]} += 10;
}
close BB;

open OUT,">$ARGV[2]" or die $!;
print OUT "Name\tSize\tGroup\n";
for my $node (sort keys %Size){
	print OUT "$node\t$Size{$node}\t$Group{$node}\n";
}
close OUT;
