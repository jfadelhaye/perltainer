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

# List of endpoints 
my $endpoints_list = "$host/api/endpoints";

my $current_time = localtime();
print("\n --- Monitoring started ($current_time) --- \n");

while (1) {
  
  my $response = $ua->get($endpoints_list);

  if ($response->is_success) {
    my $endpoints = decode_json($response->content);
    
    foreach my $endpoint (@$endpoints) {
      my $endpoint_id = $endpoint->{Id};
      my $endpoint_name = $endpoint->{Name};

      # Get the containers for the current endpoint
      # At this point we leverage docker's API throught portainer
      # path is /api/endpoints/{id}/docker/ followed by docker's API request ( here : /containers/json?all=true )
      # See https://docs.docker.com/engine/api/v1.41/#tag/Container/operation/ContainerList 

      my $containers_url = "$host/api/endpoints/$endpoint_id/docker/containers/json?all=true";
      my $containers_response = $ua->get($containers_url);
      if ($containers_response->is_success) {
        my $containers = decode_json($containers_response->content);
        
        foreach my $container (@$containers) {
          my $container_name = $container->{Names}[0];
          my $container_status = $container->{State};
          if ($container_status ne "running") {
            print(" ⚠️  $container_name is not running on host $endpoint_name. State : $container_status\n");
          } else {
            print(" ✅ $container_name is running on host $endpoint_name \n");
          }
        }
      } else {
        print "Failed to retrieve containers for endpoint $endpoint_name\n";
      }
    }
      
  } else {
    print "Failed to retrieve endpoints\n";
  }

  # Sleep for 5 minutes
  sleep(30);
  $current_time = localtime();
  print("\n --- Next iteration ($current_time) --- \n");
}
