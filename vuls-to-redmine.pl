#!/usr/bin/perl -w
use strict;
use utf8;
use Text::CSV_XS;
use Encode;
use IO::File;
use Fcntl qw(:flock);
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use Config::Tiny;
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;


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

unless (-f "$Config->{API}->{path}$Config->{API}->{files}") {
   die "$Config->{API}->{path}$Config->{API}->{files} NOT FOUND\n"
}
#   CSV DATA get
    my $csv = Text::CSV_XS->new ({ binary => 1 });
    my $io  = IO::File->new("$Config->{API}->{path}$Config->{API}->{files}", "r");
    my $columns = $csv->getline_all($io);
    my $count =  @$columns - 1;
    print "START $count data Found\n";
    for (my $l = 1; $l <= $count ; $l++){
       if ( $columns->[$l][6] ne "healthy") {
           query($Config->{API}->{server},"POST",$columns->[$l]);
       }
    }
    print "END\n";
$csv->eof;
$io->close;
exit 0;
#
sub query{
     # SUBJECT Search
     my($url,$method,$data)=@_;
     my $subject = "$data->[4] $data->[8] $data->[9]";
     my $req = HTTP::Request->new(GET => $url ."issues.json?subject=" . $subject);
     $req->content_type('application/json;charset=utf-8');
     $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
     my $ua  = LWP::UserAgent->new;
     my $res = $ua->request($req);
     unless ($res->is_success) {
          my $rtn_code = $res->is_success;
          print "PLZ Check a Access Permission return_code=$rtn_code\n";
          die($res->status_line);
     }
     my $data_ref = decode_json( $res->content );
     # SUBJECT Search NOT FOUND # ADD Ticket
     $data->[21] =~ s/"//g;
     if ($data_ref->{'total_count'} eq 0) {
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
         my $req = HTTP::Request->new($method => $url . "issues.json" );
         $req->content_type('application/json;charset=utf-8');
         $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
         $req->content($json);
         my $ua  = LWP::UserAgent->new;
         my $res = $ua->request($req);
         # Success  or unSuccess
         unless ($res->is_success) {
              return($res->status_line);
         }
     } else {
     # SUBJECT Search FOUND # ADD Notes
         my $cvss_data = 0.0;
         if ($data_ref->{"issues"}[0]->{"custom_fields"}[$Config->{API}->{cvss}-1]->{"value"} > $data->[13]) {
             $cvss_data = $data_ref->{"issues"}[0]->{"custom_fields"}[$Config->{API}->{cvss}-1]->{"value"};
         } else {
             $cvss_data = $data->[13];
         }

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
                 {"value": $cvss_data,"id":$Config->{API}->{cvss}},
                 {"value": "$data->[7]","id":$Config->{API}->{method}},
                 {"value": "$data->[11]","id":$Config->{API}->{notfix}}
             ]
          }
        }
JSON
         my $req = HTTP::Request->new(PUT => $url . "issues/" . $data_ref->{issues}->[0]->{id} . "\.json");
         $req->content_type('application/json;charset=utf-8');
         $req->header("X-Redmine-API-Key" => $Config->{API}->{key});
         $req->content($json);
         my $ua  = LWP::UserAgent->new;
         my $res = $ua->request($req);
         # Success  or unSuccess
         unless ($res->is_success) {
              print "status = $res->is_success\n";
              print "$json\n";
              return($res->status_line);
         }
     }
     return;
}
