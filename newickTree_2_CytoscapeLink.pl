#!/usr/bin/perl -w
use strict;

die "\n\tUsage: $0 Tree Subpop_name Outgroup_name
	OR: $0 Tree Subpop_name  \n\n" unless (@ARGV>=2);

my %Ancestor; my %Ancestor_ID;
my $id=0; my %Ancestor_Num;
open TREE,"$ARGV[0]" or die $!;
open TEMP,">$ARGV[0].TreeChange" or die $!;
while(<TREE>){
	chomp;
	my $tree=$_; my $ancestor;
	$tree=~s/\)\d\.\d+/\)/g;
	if (@ARGV>2){
		for my $n (2 .. $#ARGV){
			$tree=~s/$ARGV[$n]/$ARGV[1]/;
		}
	}
	while($tree =~ m/(?<=\()([^()]+)(?=\))/g){
		my $group=$1; $id++;
		my @arr=split(/,/,$group);
		my @new_arr=();
		for my $i (0 .. $#arr){
			my $target=$1 if $arr[$i]=~/(\S+):\S+/;
			push @new_arr,$target;
		}
		@new_arr=sort @new_arr;
		$ancestor=join("%",@new_arr);
		$Ancestor_ID{$ancestor}="$ARGV[1]_LUCA_$id";
		for my $str(@new_arr){
			$Ancestor{$str}=$ancestor;
			$Ancestor_Num{$str}++;
		}

		print TEMP "$tree\n";
		$tree=~s/\($group\)/$Ancestor_ID{$ancestor}/;
	}
	print TEMP "$tree\n";
}
close TREE;
close TEMP;

my %Reverse;
if (@ARGV>2){
	my @select=("$ARGV[1]");
	while(1){
		last if @select==0;
		my $selct=shift @select;
		my $ancestor=$Ancestor{$selct};
#		delete $Ancestor{$selct};
		$Reverse{$selct}=1; # print STDERR "$selct\n";
		my $newid=$Ancestor_ID{$ancestor};
		$Ancestor_Num{$newid}++;
		if ($Ancestor_Num{$newid}==2){
			push @select,$newid;
		}
	}
}

open OUT,">$ARGV[0].link" or die $!;
open ANNO,">$ARGV[0].link.nodeAnno" or die $!;
print OUT "Source\tTarget\tInteraction\n";
print ANNO "ID\tSize\tColor\n";
for my $target(keys %Ancestor){
	my $ancestor=$Ancestor{$target};
	if (defined $Reverse{$target}){
		print OUT "$target\t$Ancestor_ID{$ancestor}\t$ARGV[1]\n";
		print ANNO "$target\t5\t$ARGV[1]\n";
	}elsif(defined $Reverse{$ancestor}){
		print OUT "$Ancestor_ID{$target}\t$ancestor\t$ARGV[1]\n";
		print ANNO "$target\t5\t$ARGV[1]\n";
	}else{
		print OUT "$Ancestor_ID{$ancestor}\t$target\t$ARGV[1]\n";
		print ANNO "$target\t10\t$ARGV[1]\n";
	}
	print ANNO "$Ancestor_ID{$ancestor}\t5\t$ARGV[1]\n";
}
close OUT;
close ANNO;

# delete the LUCAs with one descendant
my %Target; my %Only;
open AA,"$ARGV[0].link" or die $!;
while(<AA>){
	chomp;
	next if $.==1;
	my @arr=split;
	push @{$Target{$arr[0]}},$arr[1];
}
close AA;

open FLT,">$ARGV[0].link.flt" or die $!;
print FLT "Source\tTarget\tInteraction\n";
for my $source(sort {$b cmp $a} keys %Target){
	my @newnew=@{$Target{$source}};
	if ($source eq $ARGV[1]){
		if (defined $Only{$newnew[0]}){
			my @newnewnew=@{$Target{$newnew[0]}};
			print FLT "$source\t$newnewnew[0]\t$ARGV[1]\n";
		}else{
			print FLT "$source\t$newnew[0]\t$ARGV[1]\n";
		}
	}elsif(@newnew==1){
		$Only{$source}=1;
		next;
	}else{
		for my $i(0 .. $#newnew){
			if (defined $Only{$newnew[$i]}){
				my @arrarr=@{$Target{$newnew[$i]}};
				print FLT "$source\t$arrarr[0]\t$ARGV[1]\n";
			}else{
				print FLT "$source\t$newnew[$i]\t$ARGV[1]\n";
			}
		}
	}
}
close FLT;

