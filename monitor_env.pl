#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Time::HiRes qw(sleep);

if (scalar @ARGV != 3) {
  die "Usage: $0 <host> <user> <password>\n";
}

my $host = shift @ARGV;
my $user = shift @ARGV;
my $password = shift @ARGV;

my $ua = LWP::UserAgent->new;

# Disable ssl verification if you are using self signed certs
$ua->ssl_opts(verify_hostname => 0, SSL_verify_mode => 0x00);
$ua->default_header('Accept' => 'application/json');
$ua->default_header('Content-Type' => 'application/json');

my $auth_url = "$host/api/auth";
my $auth_payload = {
  "Username" => $user,
  "Password" => $password
};
my $auth_response = $ua->post($auth_url, Content => encode_json($auth_payload));
die "Failed to authenticate with Portainer API\n" unless $auth_response->is_success;

# Add the jwt in every futur request
my $auth_result = decode_json($auth_response->content);
my $jwt_token = $auth_result->{jwt};
$ua->default_header('Authorization' => "Bearer $jwt_token");

# Get the list of endpoints 
my $endpoints_list = "$host/api/endpoints";

while (1) {
  my $response = $ua->get($endpoints_list);

  if ($response->is_success) {
    my $endpoints = decode_json($response->content);
    my @down_endpoints;
    foreach my $endpoint (@$endpoints) {
      # Skip local/socket endpoints
      next if ($endpoint->{URL} =~ /unix/);
      my $endpoint_id = $endpoint->{Id};
      my $endpoint_name = $endpoint->{Name};
      my $endpoint_status = $endpoint->{Status};
      my $endpoint_heartbeat = $endpoint->{Heartbeat};
      my $endpoint_url = $endpoint->{URL};

      if ( $endpoint_status != 1 || $endpoint_heartbeat != 1) {
        push @down_endpoints, $endpoint;
      }
    }

    if (scalar @down_endpoints > 0) {
      print "The following endpoints are down ! 😱 \n";
      foreach my $down_endpoint (@down_endpoints) {
        my $down_endpoint_name = $down_endpoint->{Name};
        print "\t- $down_endpoint_name\n";
      }
    } else {
      print "All endpoints are up 🥳\n";
    }
    
  } else {
    print "Failed to retrieve endpoints\n";
  }

  # Sleep for 5 minutes
  sleep(30);
}
