#!/usr/bin/perl -w
use strict;

die "\n\tUsage: $0 Link_1 Link_2 ... Link_n res-Prefix \n\n" if @ARGV<3;

my $prefix=pop @ARGV;

my (%Desc,%Pop,%Samp);
for my $i (0 .. $#ARGV){
	open AA,"$ARGV[$i]" or die $!;
	while(<AA>){
		chomp;
		next if $.==1;
		my ($ancs,$desc,$pop)=split;
		push @{$Desc{$ARGV[$i]}{$ancs}},$desc;
		$Pop{$ancs}=$pop;
		next if $desc=~/LUCA/;
		push @{$Samp{$ARGV[$i]}},$desc;
	}
	close AA;
}
my %DescArr;
for my $i (0 .. $#ARGV){
	for my $ancs(keys %{$Desc{$ARGV[$i]}}){
		my @arr=sort @{$Desc{$ARGV[$i]}{$ancs}}; # 20200826 排序保留了各层级结构，有助于后续的共同祖先比较
		$DescArr{$ancs}=join(":",@arr);
	}
}

open OUT,">$prefix.mergeLink" or die $!;
print OUT "Source\tTarget\tInteraction\n";
open SAME,">$prefix.sameLUCA" or die $!;
print SAME "New_LUCA_ID\tLUCA1_ID\tLUCA2_ID\n";

my $same_id=0; my (%Same,%New_pop);
my @trees=@ARGV;

while(1){
	my $tree=shift @trees;
	last if @trees==0;
	my @sample0=@{$Samp{$tree}};
	my $sample0_str=join("\t",@{$Samp{$tree}});
	my @Ancs0=keys %{$Desc{$tree}};

	for my $m (0 .. $#trees){
		my $sample1=@{$Samp{$trees[$m]}};
		my $sample1_str=join("\t",@{$Samp{$trees[$m]}});
		my $overlap=Arr_Overlap_Num($sample0_str,$sample1_str);
		my @Ancs1=keys %{$Desc{$trees[$m]}};

		if ($overlap<2){
			system("tail -n +2 $tree >>$prefix.mergeLink");
			system("tail -n +2 $trees[$m] >>$prefix.mergeLink");
		}else{
			my %hash=();
			++$hash{$_} foreach(@Ancs0,@Ancs1);
			my @Ancs_tot=keys %hash;

			while(1){
				my $first=shift @Ancs_tot;
				last if @Ancs_tot==0;
				for my $n (0 .. $#Ancs_tot){
					my $res=LUCA_Same($first,$Ancs_tot[$n]);
					my @arr1; my @arr2;
					if (defined $Desc{$tree}{$first}){
						@arr1=sort @{$Desc{$tree}{$first}};
					}else{
						@arr1=sort @{$Desc{$trees[$m]}{$first}};
					}
					if (defined $Desc{$tree}{$Ancs_tot[$n]}){
						@arr2=sort @{$Desc{$tree}{$Ancs_tot[$n]}};
					}else{
						@arr2=sort @{$Desc{$trees[$m]}{$Ancs_tot[$n]}};
					}	

					if ($res eq 'Yes'){
						$same_id++;
						my @pap_arr=sort ($Pop{$first},$Pop{$Ancs_tot[$n]});
						my %hash1=();
						@pap_arr=grep { ++$hash1{$_}<2 } @pap_arr;
						my $new_pop=join("_",@pap_arr);
						print SAME "Same_LUCA_$same_id\t$first\t$Ancs_tot[$n]\n";
						$Same{$first}="Same_LUCA_$same_id";
						$Same{$Ancs_tot[$n]}="Same_LUCA_$same_id";
						$New_pop{$first}=$new_pop;
						$New_pop{$Ancs_tot[$n]}=$new_pop;

						for my $i (0 .. $#arr1){
							print OUT "Same_LUCA_$same_id\t$arr1[$i]\t$new_pop\n";
						}
                        			for my $i (0 .. $#arr2){
                                			print OUT "Same_LUCA_$same_id\t$arr2[$i]\t$new_pop\n";
                        			}
					}else{
                        			for my $i (0 .. $#arr1){
                                			print OUT "$first\t$arr1[$i]\t$Pop{$first}\n";
                        			}
                        			for my $i (0 .. $#arr2){
                                			print OUT "$Ancs_tot[$n]\t$arr2[$i]\t$Pop{$Ancs_tot[$n]}\n";
                        			}
					}
				}
			}
		}
	}
}
close OUT;
close SAME;

system("head -n 1 $prefix.mergeLink >$prefix.uniq.mergeLink");
system("tail -n +2 $prefix.mergeLink |sort -u >>$prefix.uniq.mergeLink");
system("rm $prefix.mergeLink");
system("mv $prefix.uniq.mergeLink $prefix.mergeLink");

open BB,"$prefix.mergeLink" or die $!;
open CC,">$prefix.mergeLink.new" or die $!;
while(<BB>){
	chomp;
	if ($.==1){
		print CC "$_\n";
	}else{
		my @arr=split;
		$arr[2]=$New_pop{$arr[0]} if defined $New_pop{$arr[0]};
#                $arr[2]=$New_pop{$arr[1]} if defined $New_pop{$arr[1]};
		$arr[0]=$Same{$arr[0]} if defined $Same{$arr[0]};
		$arr[1]=$Same{$arr[1]} if defined $Same{$arr[1]};
		my $new=join("\t",@arr);
		print CC "$new\n";
	}
}
close BB;
close CC;

system("rm $prefix.mergeLink");
system("head -n 1 $prefix.mergeLink.new >$prefix.mergeLink");
system("tail -n +2 $prefix.mergeLink.new|sort -u >>$prefix.mergeLink");
system("rm $prefix.mergeLink.new");

###########################################################################################
sub LUCA_Same{
	my ($luca1,$luca2)=@_;
	
	while($luca1=~/:?([^:]+_LUCA_\d+):?/g){
		my $luca11=$1;
		$luca1=~s/$luca11/$DescArr{$luca11}/;
	}

	while($luca2=~/:?([^:]+_LUCA_\d+):?/g){
		my $luca21=$1;
		$luca2=~s/$luca21/$DescArr{$luca21}/;
	}

	if ($luca1 eq $luca2){
		return "Yes";
	}else{
		return "No";
	}
}

##########################################################################################
sub All_Desc{
	my ($desc0)=@_;
	while($desc0=~/:?([^:]+_LUCA_\d+):?/g){
		my $str0=$1;
		$desc0=~s/$str0/$DescArr{$str0}/;
	}
	return $desc0;
}

##########################################################################################
sub Arr_Overlap_Num{
	my ($str1,$str2)=@_;
	my @test1=split(/\t/,$str1);
	my @test2=split(/\t/,$str2);

	my %Num=(); my $num=0;
	for my $m (0 .. $#test1){
		$Num{$test1[$m]}++;
	}
	for my $m (0 .. $#test2){
                $Num{$test2[$m]}++;
        }
	for my $samp_test(keys %Num){
		if ($Num{$samp_test}==2){
			$num++;
		}
	}
	return $num;
}

