#!/usr/bin/perl -w
use strict;
use Text::CSV_XS;
use Fcntl qw(:flock);
use IO::File;
use Encode;
use Config::Tiny;
use Time::HiRes qw/usleep/;

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
    my $in_old  = IO::File->new("$Config->{API}->{oldpath}/$Config->{API}->{oldfiles}", "r");
    my $in_new  = IO::File->new("$Config->{API}->{newpath}/$Config->{API}->{newfiles}", "r");
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
    print "START OLD $count_old Count\n";
    print "START NEW $count_new Count\n";
    print "S" . " "x48 . "E\n";
    $| = 1;
    for ( my $o = 0 ; $o <= $count_old ; $o++ ) {
       my $dec_old = encode('utf-8',$columns_old->[$o][21]);
       my $old_key = $columns_old->[$o][8] . $columns_old->[$o][9] .  $columns_old->[$o][4];
#X#       print "count_o = $o \n";
       update_progress($o, $count_old);
       usleep 10_000;

       for ( my $n = 0 ; ( $n <= $count_new ) && ( $columns_old->[$o][1] ne "" ) ; $n++ ) {
           if ( ( $columns_old->[$o][1] ne "" ) && ( $columns_new->[$n][1] ne "" )) {
               my $dec_new = encode('utf-8',$columns_new->[$n][21]);
               my $new_key = $columns_new->[$n][8] . $columns_new->[$n][9] . $columns_new->[$n][4];
               if ( $old_key  eq  $new_key ) {
                   #  CVE Check
                   if ( $columns_old->[$o][6] eq $columns_new->[$n][6] ) {
                       #  CWE Check
                       if ( $columns_old->[$o][12] eq $columns_new->[$n][12] ) {
                           #  Version Check
                           if ( $columns_old->[$o][10] eq $columns_new->[$n][10] ) {
                               #  Desc
                               if ( $dec_old eq $dec_new ) {
                                   $columns_old->[$o][1] = "";
                                   $columns_new->[$n][1] = "";
                                   $n = $count_new;
                               } else {
                                   $columns_old->[$o][1] = "";
                                   $n = $count_new;
                               }
                           }
                       }
                   }
               }
           }
       }
    }
    ### OLD DATA OUTPUT
    my $output_count = 0;
    for (my $l = 0; $l <= $count_old ; $l++){
       if ( $columns_old->[$l][6] eq "healthy" || $columns_old->[$l][0] eq "ScannedAt" ) {
           $columns_old->[$l][1] = "";
        }
       if ( $columns_old->[$l][1] ne "" ) {
           $output_count++;
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
       if ( $columns_new->[$l][6] eq "healthy" || $columns_new->[$l][0] eq "ScannedAt" ) {
           $columns_new->[$l][1] = "";
        }
       if ( $columns_new->[$l][1] ne "" ) {
           $output_count++;
           $columns_new->[$l][21]=~ s/"/""/g;
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
    print "END OUTPUT $output_count Count\n";
exit;

sub update_progress {
    my $progress = ($_[0] / $_[1]) * 100 / (100/50);
    print '.'x$progress . "\r";
}
