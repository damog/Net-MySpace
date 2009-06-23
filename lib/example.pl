#!/opt/local/bin/perl

use Modern::Perl;
use Data::Dumper;
use Net::MySpace;

my $consumer_key 		= '';
my $consumer_secret 	= '';

my $ms = Net::MySpace:->new(
	consumer_key 		=> $consumer_key,
	consumer_secret 	=> $consumer_secret,
);

say $ms->oauth->get_authorization_url(
	oauth_callback => "http://localhost/authorized"
);

<STDIN>;

# my($access_token, $access_token_secret) = $client->oauth->request_access_token;

print Dumper $ms->oauth->request_access_token;

print Dumper $ms->friends_status(
	userId => $ms->user->{userId}
);
