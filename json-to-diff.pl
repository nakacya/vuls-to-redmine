#!/usr/bin/perl -w
use strict;
use Text::CSV_XS;
use File::Sort qw(sort_file);
use Fcntl qw(:flock);
use IO::File;
use Config::Tiny;

if (@ARGV < 2){
   die "USAGE: perl test_diff.pl -c param.conf\n";
}
use Getopt::Std;
my %opts = ();
getopt ('c:',\%opts);

my $Config = Config::Tiny->new;
unless (-f "$opts{'c'}") {
   die "$opts{'c'} NOT FOUND\n"
}
$Config = Config::Tiny->read( "$opts{'c'}" );

unless (-f "$Config->{API}->{oldpath}/$Config->{API}->{oldfiles}") {
   die "$Config->{API}->{oldpath}/$Config->{API}->{oldfiles} NOT FOUND\n"
}
unless (-f "$Config->{API}->{newpath}/$Config->{API}->{newfiles}") {
   die "$Config->{API}->{newpath}/$Config->{API}->{newfiles} NOT FOUND\n"
}
    sort_file({
       t => ",",
       k => "3,4,5,6,7,8,11",
       I => "$Config->{API}->{oldpath}/$Config->{API}->{oldfiles}",
       o => "$Config->{API}->{oldpath}/tmp_old.csv",
    });
    sort_file({
       t => ",",
       k => "3,4,5,6,7,8,11",
       I => "$Config->{API}->{newpath}/$Config->{API}->{newfiles}",
       o => "$Config->{API}->{newpath}/tmp_new.csv",
    });
    my $in_old  = IO::File->new("$Config->{API}->{oldpath}/tmp_old.csv", "r");
    my $in_new  = IO::File->new("$Config->{API}->{newpath}/tmp_new.csv", "r");
    my $io_out  = IO::File->new("$Config->{API}->{path}/$Config->{API}->{files}", "w");
    my $csv_old = Text::CSV_XS->new ({ binary => 1 });
    my $columns_old = $csv_old->getline_all($in_old);
    my $csv_new = Text::CSV_XS->new ({ binary => 1 });
    my $columns_new = $csv_new->getline_all($in_new);

    my $count =  1;
    my $count_old =  @$columns_old - 1;
    my $count_new =  @$columns_new - 1;
    if ($count_old > $count_new) {
       $count = $count_old;
    } else {
       $count = $count_new;
    }

    my $m = 0;
    for (my $l = 0; $l <= $count ; $l++){
       if ($columns_old->[$l][1] eq $columns_new->[$m][1] and
           $columns_old->[$l][2] eq $columns_new->[$m][2] and
           $columns_old->[$l][3] eq $columns_new->[$m][3] and
           $columns_old->[$l][4] eq $columns_new->[$m][4] and
           $columns_old->[$l][5] eq $columns_new->[$m][5] and
           $columns_old->[$l][6] eq $columns_new->[$m][6] and
           $columns_old->[$l][7] eq $columns_new->[$m][7] and
           $columns_old->[$l][8] eq $columns_new->[$m][8] and
           $columns_old->[$l][9] eq $columns_new->[$m][9] and
           $columns_old->[$l][10] eq $columns_new->[$m][10] and
           $columns_old->[$l][11] eq $columns_new->[$m][11] and
           $columns_old->[$l][12] eq $columns_new->[$m][12] and
           $columns_old->[$l][13] eq $columns_new->[$m][13] and
           $columns_old->[$l][14] eq $columns_new->[$m][14] and
           $columns_old->[$l][15] eq $columns_new->[$m][15] and
           $columns_old->[$l][16] eq $columns_new->[$m][16] and
           $columns_old->[$l][17] eq $columns_new->[$m][17] and
           $columns_old->[$l][18] eq $columns_new->[$m][18] and
           $columns_old->[$l][19] eq $columns_new->[$m][19] and
           $columns_old->[$l][20] eq $columns_new->[$m][20] and
           $columns_old->[$l][21] eq $columns_new->[$m][21] and
           $columns_old->[$l][22] eq $columns_new->[$m][22] and
           $columns_old->[$l][23] eq $columns_new->[$m][23]) {
               $columns_old->[$l][1] = "";
               $columns_new->[$m][1] = "";
               $m++;
       } else {
           if  ( $columns_old->[$l][3] eq $columns_new->[$m][3] and
                 $columns_old->[$l][4] eq $columns_new->[$m][4] and
                 $columns_old->[$l][5] eq $columns_new->[$m][5] and
                 $columns_old->[$l][6] eq $columns_new->[$m][6] and
                 $columns_old->[$l][7] eq $columns_new->[$m][7] and
                 $columns_old->[$l][8] eq $columns_new->[$m][8] and
                 $columns_old->[$l][11] eq $columns_new->[$m][11] and
                 $columns_old->[$l][21] eq $columns_new->[$m][21] ) {
                 if ( $columns_old->[$l][23] < $columns_new->[$m][23] ) {
                    $columns_old->[$l][1] = "";
                 }
                 $m++;
           } else {
                 my $old_key = $columns_old->[$l][3] . $columns_old->[$l][4] .
                               $columns_old->[$l][5] . $columns_old->[$l][6] .
                               $columns_old->[$l][7] . $columns_old->[$l][8] .
                               $columns_old->[$l][11];
                 my $new_key = $columns_new->[$m][3] . $columns_new->[$m][4] .
                               $columns_new->[$m][5] . $columns_new->[$m][6] .
                               $columns_new->[$m][7] . $columns_new->[$m][8] .
                               $columns_new->[$m][11];
                 if ( $old_key gt $new_key ) {
                     $m++;
                     $l--;
                 }
           }
       }
    }
    flock($io_out, LOCK_EX);
    ### OLD DATA OUTPUT
    for (my $l = 0; $l <= $count_old ; $l++){
       if ( $columns_old->[$l][6] ne "healthy" and $columns_old->[$l][1] ne "" and $columns_old->[$l][0] ne "ScannedAt" ) {
           print $io_out '"' . $columns_old->[$l][0] . '",' .
                         '"' . $columns_old->[$l][1] . '",' .
                         '"' . $columns_old->[$l][2] . '",' .
                         '"' . $columns_old->[$l][3] . '",' .
                         '"' . $columns_old->[$l][4] . '",' .
                         '"' . $columns_old->[$l][5] . '",' .
                         '"' . $columns_old->[$l][6] . '",' .
                         '"' . $columns_old->[$l][7] . '",' .
                         '"' . $columns_old->[$l][8] . '",' .
                         '"' . $columns_old->[$l][9] . '",' .
                         '"' . $columns_old->[$l][10] . '",' .
                         '"' . $columns_old->[$l][11] . '",' .
                         '"' . $columns_old->[$l][12] . '",' .
                         '"' . $columns_old->[$l][13] . '",' .
                         '"' . $columns_old->[$l][14] . '",' .
                         '"' . $columns_old->[$l][15] . '",' .
                         '"' . $columns_old->[$l][16] . '",' .
                         '"' . $columns_old->[$l][17] . '",' .
                         '"' . $columns_old->[$l][18] . '",' .
                         '"' . $columns_old->[$l][19] . '",' .
                         '"' . $columns_old->[$l][20] . '",' .
                         '"' . "CLOSED!!" . '",' .
                         '"' . $columns_old->[$l][22] . '",' .
                         '"' . $columns_old->[$l][23] . '"' .  "\n";
       }
    }
    ### NEW DATA OUTPUT
    for (my $l = 0; $l <= $count_new ; $l++){
       if ( $columns_new->[$l][6] ne "healthy" and $columns_new->[$l][1] ne "" and $columns_new->[$l][0] ne "ScannedAt" ) {
           print $io_out '"' . $columns_new->[$l][0] . '",' .
                         '"' . $columns_new->[$l][1] . '",' .
                         '"' . $columns_new->[$l][2] . '",' .
                         '"' . $columns_new->[$l][3] . '",' .
                         '"' . $columns_new->[$l][4] . '",' .
                         '"' . $columns_new->[$l][5] . '",' .
                         '"' . $columns_new->[$l][6] . '",' .
                         '"' . $columns_new->[$l][7] . '",' .
                         '"' . $columns_new->[$l][8] . '",' .
                         '"' . $columns_new->[$l][9] . '",' .
                         '"' . $columns_new->[$l][10] . '",' .
                         '"' . $columns_new->[$l][11] . '",' .
                         '"' . $columns_new->[$l][12] . '",' .
                         '"' . $columns_new->[$l][13] . '",' .
                         '"' . $columns_new->[$l][14] . '",' .
                         '"' . $columns_new->[$l][15] . '",' .
                         '"' . $columns_new->[$l][16] . '",' .
                         '"' . $columns_new->[$l][17] . '",' .
                         '"' . $columns_new->[$l][18] . '",' .
                         '"' . $columns_new->[$l][19] . '",' .
                         '"' . $columns_new->[$l][20] . '",' .
                         '"' . $columns_new->[$l][21] . '",' .
                         '"' . $columns_new->[$l][22] . '",' .
                         '"' . $columns_new->[$l][23] . '"' .  "\n";
       }
    }
    flock($io_out, LOCK_UN);
    $io_out->close;
    $in_new->close;
    $in_old->close;
exit;
