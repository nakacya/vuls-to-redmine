#!/usr/bin/perl -w
use strict;
use Text::CSV_XS;
use File::Sort qw(sort_file);
use Fcntl qw(:flock);
use IO::File;
use Encode;
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
       k => '8f,9n,6n,12n',
       I => "$Config->{API}->{oldpath}/$Config->{API}->{oldfiles}",
       o => "$Config->{API}->{oldpath}/tmp_old.csv",
    });
    sort_file({
       t => ",",
       k => '8f,9n,6n,12n',
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
#X#       print "old = " . $count_old . "\n";
#X#       print "new = " . $count_new . "\n";

    my $n = 0;
    my $o = 0;
    for ( my $l = 0 ; ($o <= $count_old && $n <= $count_new) ; $l++ ) {
       my $dec_old = encode('utf-8',$columns_old->[$o][21]);
       my $dec_new = encode('utf-8',$columns_new->[$n][21]);

       my $old_key = $columns_old->[$o][8] . $columns_old->[$o][9] .
                     $columns_old->[$o][6] . $columns_old->[$o][12] . $columns_old->[$o][4];
       my $new_key = $columns_new->[$n][8] . $columns_new->[$n][9] .
                     $columns_new->[$n][6] . $columns_new->[$n][12] . $columns_new->[$n][4];

#       print "old_key = " . $old_key . "\n";
#       print "new_key = " . $new_key . "\n";
#       print "o = " . $o . "\n";
#       print "n = " . $n . "\n";
#       print "OLD DATA = " . $columns_old->[$o][6] . "  " . $dec_old . "\n";
#       print "NEW DATA = " . $columns_new->[$n][6] . "  " . $dec_new . "\n";

       if ( $old_key eq $new_key ) {
            if ( $columns_old->[$o][10] eq $columns_new->[$n][10] ) {
                if ( $dec_old eq $dec_new ) {
                    $columns_old->[$o][1] = "";
                    $columns_new->[$n][1] = "";
                    $o++;
                    $n++;
#X#                    print "section DELETE\n";
                 } else {
                    $columns_old->[$o][1] = "";
                    $o++;
                    $n++;
#X#                    print "section OLD_DELETE_1\n";
                 }
            } else {
                $columns_old->[$o][1] = "";
                $o++;
                $n++;
#X#                print "section OLD DELETE_2\n";
            }
       } else {
            if ( $old_key gt $new_key ) {
                if ( $o <  $count_old ) {
                   $columns_old->[$o][21] = "CLOSED!!";
                   $o++;
                   if ( $n < $count_new ) {
                      $columns_new->[$n][1] = "";
                      $n++;
                   }
                } else {
                   $n++;
                }
#X#                print "section OLD CLOSE_gt\n";
            } else {
#X#                print "o = $o\n";
#X#                print "n = $n\n";
#X#                print "count_old = $count_old\n";
#X#                print "count_new = $count_new\n";
                if ( $o <  $count_old ) {
                   $columns_old->[$o][21] = "CLOSED!!";
                   $o++;
                   if ( $n < $count_new ) {
                      $columns_new->[$n][1] = "";
                      $n++;
                   }
                } else {
                   $n++;
                }
#X#                print "section OLD CLOSE_le\n";
            }
       }
#       $a = <STDIN>;
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
                         '"' . "@{[encode('utf-8', $columns_old->[$l][21])]}" . '",' .
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
                         '"' . "@{[encode('utf-8', $columns_new->[$l][21])]}" . '",' .
                         '"' . $columns_new->[$l][22] . '",' .
                         '"' . $columns_new->[$l][23] . '"' .  "\n";
       }
    }
    flock($io_out, LOCK_UN);
    $io_out->close;
    $in_new->close;
    $in_old->close;
exit;
