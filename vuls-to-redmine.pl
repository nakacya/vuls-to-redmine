#!/usr/bin/perl -w
use strict;
use utf8;
use Text::CSV_XS;
use Encode;
use IO::File;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use Config::Tiny;
use Time::HiRes qw/usleep/;

if (@ARGV < 2){
   die "USAGE: perl vuls-to-redmine.pl -c param.conf\n";
}
use Getopt::Std;
my %opts = ();
getopt ('c:',\%opts);

my $Config = Config::Tiny->new;
unless (-f "$opts{'c'}") {
   die "$opts{'c'} NOT FOUND\n"
}
$Config = Config::Tiny->read( "$opts{'c'}" );

unless (-f "$Config->{API}->{path}/$Config->{API}->{files}") {
   die "$Config->{API}->{path}/$Config->{API}->{files} NOT FOUND\n"
}

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = $Config->{API}->{ssl_fail};
#   CSV DATA get
    my $csv = Text::CSV_XS->new ({
     'quote_char'  => '"',
     'escape_char' => '"',
     'sep_char'    => ',',
     'binary'      => 1,
     'always_quote' => undef
    });
    my $io  = IO::File->new("$Config->{API}->{path}/$Config->{API}->{files}", "r");
    my $columns = $csv->getline_all($io);
    my $count =  @$columns;
    our %close;
    print "START $count data Found\n";
    print "S" . " "x48 . "E\n";
    $| = 1;
    # Ticket POST/PUT
    for (my $l = 0; $l <+ $count - 1 ; $l++){
        update_progress($l, $count - 1);
        usleep 10_000;
        if (( $columns->[$l][0] ne "ScannedAt" ) && ( $columns->[$l][9] ne "PackageVer" )){
           query($Config->{API}->{server},"POST",$columns->[$l]);
        }
    }
    # Ticket CLOSED
    while ( my ($key,$val) = each %close ) {
        close_API($Config->{API}->{server},"PUT",$key,$val);
    }
    print "END\n";
$csv->eof;
$io->close;
exit 0;
#
sub close_API{
     my($url,$method,$subject,$data)=@_;
     # SUBJECT Search
     my $req = HTTP::Request->new(GET => $url ."issues.json?subject=" . $subject);
     $req->content_type('application/json;charset=utf-8');
     $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
     my $ua  = LWP::UserAgent->new();
     my $res = $ua->request($req);
     unless ($res->is_success) {
          my $rtn_code = $res->is_success;
          print "PLZ Check a Access Permission return_code=$rtn_code\n";
          print "$res->status_line\n";
          die($res->status_line);
     }
     my $data_ref = decode_json( $res->content );
my $json = <<"JSON";
     {
      "issue": {
        "project_id": $Config->{API}->{project_id},
        "tracker_id": $Config->{API}->{tracker_id},
        "status_id": $Config->{API}->{closed_status_id},
        "assigned_to_id": $Config->{API}->{assigned_to_id},
        "done_ratio": 100,
        "subject": "$subject",
        "notes": "\[\[ @{[encode('utf-8', $data->[21])]} \]\]",
        "custom_fields":
      }
     }
JSON
     $req = HTTP::Request->new(PUT => $url . "issues/" . $data_ref->{issues}->[0]->{id} . "\.json");
     $req->content_type('application/json;charset=utf-8');
     $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
     $req->content($json);
     $ua  = LWP::UserAgent->new();
     $res = $ua->request($req);
     # Success  or unSuccess
     unless ($res->is_success) {
          print "CLOSE status = $subject\n";
          print "$res->status_line\n";
          return($res->status_line);
     }
     return;
}

sub query{
     my($url,$method,$data)=@_;
     # SUBJECT Search(OpenTicket)
     my $subject = "$data->[4] " . "$data->[8] " . "$data->[9]";
     my $req = HTTP::Request->new(GET => $url ."issues.json?status_id=open&subject=" . $subject );
     $req->content_type('application/json;charset=utf-8');
     $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
     my $ua  = LWP::UserAgent->new();
     my $res = $ua->request($req);
     unless ($res->is_success) {
          my $rtn_code = $res->is_success;
          print "PLZ Check a Access Permission return_code=$rtn_code\n";
          print "GET status = $subject\n";
          print "$res->status_line\n";
          die($res->status_line);
     }
#X#     my $data_ref = decode_json( $res->content );
     ### OPEN Ticket NOT FOUND
     my $data_ref = decode_json( $res->content );
     if ($data_ref->{'total_count'} eq 0) {
         # SUBJECT Search(ClosedTicket)
         $req = HTTP::Request->new(GET => $url ."issues.json?status_id=closed&subject=" . $subject );
         $req->content_type('application/json;charset=utf-8');
         $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
         $ua  = LWP::UserAgent->new();
         $res = $ua->request($req);
         unless ($res->is_success) {
              my $rtn_code = $res->is_success;
              print "PLZ Check a Access Permission return_code=$rtn_code\n";
              print "$res->status_line\n";
              die($res->status_line);
         }
     }
     # SUBJECT Search NOT FOUND # ADD Ticket
     $data_ref = decode_json( $res->content );
     $data->[21] =~ s/"/&quot;/g;
     my $cvss_data = 0.0;
     if ( $data->[13] !~ /^([+-]?\d+)(\.?\d+)?$/ ) {
         $data->[13] = 0;
     }
     if ( $data->[13] eq "Unknown" ) {
         $data->[13] = 0;
     }
     if ($data_ref->{'total_count'} eq 0) {
        # SUBJECT Search FOUND # CLOSED
        if ( $data->[21] eq "CLOSED!!" ) {
            $close{$subject} = $data;
        }
my $json = <<"JSON";
        {
          "issue": {
            "project_id": $Config->{API}->{project_id},
            "tracker_id": $Config->{API}->{tracker_id},
            "status_id": $Config->{API}->{status_id},
            "assigned_to_id": $Config->{API}->{assigned_to_id},
            "subject": "$data->[4] $data->[8] $data->[9]",
            "description": "@{[encode('utf-8', $data->[21])]} \\n\\nCVEID: $data->[6] \\n\\nCWEID: $data->[12] \\n\\nOS: $data->[2] $data->[3] \\nPackage: $data->[8] $data->[9] \\nNewPackage: $data->[10] \\nDetectionMethod: $data->[7] \\nCVSS Score:$data->[13]($data->[14])",
            "custom_fields":
             [
                 {"value": $data->[13],"id":$Config->{API}->{cvss}},
                 {"value": "$data->[7]","id":$Config->{API}->{method}},
                 {"value": "$data->[11]","id":$Config->{API}->{notfix}}
             ]
          }
        }
JSON
         $req = HTTP::Request->new($method => $url . "issues.json" );
         $req->content_type('application/json;charset=utf-8');
         $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
         $req->content($json);
         $ua  = LWP::UserAgent->new();
         $res = $ua->request($req);
         # Success  or unSuccess
         unless ($res->is_success) {
              print "POST status = $subject\n";
              print Dumper($json);
              print "$res->status_line\n";
              return($res->status_line);
         }
         return;
     }
     # SUBJECT Search FOUND # GET DATA
     if ($data_ref->{"issues"}[0]->{"custom_fields"}[$Config->{API}->{cvss}-1]->{"value"} > $data->[13]) {
         $cvss_data = $data_ref->{"issues"}[0]->{"custom_fields"}[$Config->{API}->{cvss}-1]->{"value"};
     } else {
         $cvss_data = $data->[13];
     }
     # SUBJECT Search FOUND # CLOSED
     if ( $data->[21] eq "CLOSED!!" ) {
         $close{$subject} = $data;
     } else {
         delete($close{$subject});
     }
     # SUBJECT Search FOUND # ADD Notes
my $json = <<"JSON";
        {
          "issue": {
            "project_id": $Config->{API}->{project_id},
            "tracker_id": $Config->{API}->{tracker_id},
            "status_id": $Config->{API}->{status_id},
            "assigned_to_id": $Config->{API}->{assigned_to_id},
            "subject": "$data->[4] $data->[8] $data->[9]",
            "notes": "@{[encode('utf-8', $data->[21])]} \\n\\nCVEID: $data->[6] \\n\\nCWEID: $data->[12] \\n\\nOS: $data->[2] $data->[3] \\nPackage: $data->[8] $data->[9] \\nNewPackage: $data->[10] \\nDetectionMethod: $data->[7] \\nCVSS Score:$data->[13]($data->[14])",
            "custom_fields":
             [
                 {"value": "$cvss_data","id":$Config->{API}->{cvss}},
                 {"value": "$data->[7]","id":$Config->{API}->{method}},
                 {"value": "$data->[11]","id":$Config->{API}->{notfix}}
             ]
          }
        }
JSON
         $req = HTTP::Request->new(PUT => $url . "issues/" . $data_ref->{issues}->[0]->{id} . "\.json");
         $req->content_type('application/json;charset=utf-8');
         $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
         $req->content($json);
         $ua  = LWP::UserAgent->new();
         $res = $ua->request($req);
         # Success  or unSuccess
         unless ($res->is_success) {
              print "PUT status = $subject\n";
              print Dumper($json);
              print Dumper($res->status_line);
              return($res->status_line);
         }
     return;
}

sub update_progress {
    my $progress = ($_[0] / $_[1]) * 100 / (100/50);
    print '.'x$progress . "\r";
}
