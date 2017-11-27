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
# プロパティの読み取り
our $config_key = $Config->{API}->{key};
our $config_project_id = $Config->{API}->{project_id};
our $config_tracker_id = $Config->{API}->{tracker_id};
our $config_status_id = $Config->{API}->{status_id};
our $config_assigned_to_id = $Config->{API}->{assigned_to_id};
our $config_path = $Config->{API}->{path};
our $config_files = $Config->{API}->{files};
our $config_server = $Config->{API}->{server};
our $config_port = $Config->{API}->{port};

unless (-f "$config_path$config_files") {
   die "$config_path$config_files NOT FOUND\n"
   }
   #   CSV DATA get
   my $csv = Text::CSV_XS->new ({ binary => 1 });
   my $io  = IO::File->new("$Config->{API}->{path}$Config->{API}->{files}", "r");
   my $columns = $csv->getline_all($io);
   for (my $l = 1; $l <= @$columns-1 ; $l++){
      if ( $columns->[$l][6] ne "healthy") {
          query($config_server,"POST",$columns->[$l]);
      }
   }
   $csv->eof;
   $io->close;
exit 0;
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
          die $res->status_line;
     }
     my $data_ref = decode_json( $res->content );
     # SUBJECT Search NOT FOUND # ADD Ticket
     $data->[21] =~ s/"//g;
     if ($data_ref->{'total_count'} eq 0) {
my $json = <<"JSON";
   {
     "issue": {
        "project_id": $config_project_id,
        "tracker_id": $config_tracker_id,
        "status_id": $config_status_id,
        "subject": "$data->[4] $data->[8] $data->[9]",
        "description": "@{[encode('utf-8', $data->[21])]} \\n\\nCVEID: $data->[6] \\n\\nCWEID: $data->[12] \\n\\nOS: $data->[2] $data->[3] \\nPackage: $data->[8] $data->[9] \\nNewPackage: $data->[10] \\nDetectionMethod: $data->[7] \\nCVSS Score:$data->[13]($data->[14])",
         "assigned_to_id": $config_assigned_to_id,
         "custom_fields":
             [
                 {"value": $data->[13],"id":1},
                 {"value": "$data->[7]","id":2},
                 {"value": "$data->[11]","id":3}
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
             return;
             die "Check Permissions Of Access $res->status_line\n";
         }
      } else {
      # SUBJECT Search FOUND # ADD Notes
my $json = <<"JSON";
     {
        "issue": {
           "project_id": $config_project_id,
           "tracker_id": $config_tracker_id,
           "status_id": $config_status_id,
           "subject": "$data->[4] $data->[8] $data->[9]",
           "notes": "@{[encode('utf-8', $data->[21])]} \\n\\nCVEID: $data->[6] \\n\\nCWEID: $data->[12] \\n\\nOS: $data->[2] $data->[3] \\nPackage: $data->[8] $data->[9] \\nNewPackage: $data->[10] \\nDetectionMethod: $data->[7] \\nCVSS Score:$data->[13]($data->[14])",
            "assigned_to_id": $config_assigned_to_id,
            "custom_fields":
                  [
                      {"value": $data->[13],"id":1},
                      {"value": "$data->[7]","id":2},
                      {"value": "$data->[11]","id":3}
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
