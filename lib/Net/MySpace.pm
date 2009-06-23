package Net::MySpace;

=head1 NAME

Net::MySpace - MySpaceID SDK for Perl

=head1 SYNOPSIS
 
 use Net::MySpace;
 
 my $ms = Net::MySpace->new(
 	consumer_key => $consumer_key,
 	consumer_secret => $consumer_secret,
 );

 # If you already have the access tokens, you should use them
 # here, to request access:
 if ($access_token && $access_token_secret) {
     $ms->oauth->access_token($access_token);
     $ms->oauth->access_token_secret($access_token_secret);
 }
 # otherwise, it means it's a new access
 
 # in any case, you will need to verify authorization:
 # unless ($ms->oauth->authorized) {
 	say "Go to: ".$ms->get_authorization_url;
 	<STDIN>; # waiting for the user to hit ENTER

 	# once the user has granted access to your application,
 	# you can store the access token to use later on on new
 	# program executions
 	my($access_token, $access_token_secret) = $ms->oauth->request_access_token;
 }

 my $user = $ms->user;

 my $friends_status = $ms->friends_status(
 	userId => $user
 );

=cut

use Modern::Perl;
use Data::Dumper;
use Carp;

use Net::OAuth::Simple;
use JSON::Any;

our $VERSION = '0.001';
our $API_URL = 'http://api.myspace.com';
our $API_VERSION = 'v1';
our $API_FORMAT = 'json';

=head1 DESCRIPTION

Some bullshit.

=cut

sub new {
	my $class = shift;
	my $self = {};
	$self->{oauth} = Net::OAuth::Simple->new(
		tokens => {@_},
		urls => {
			request_token_url 	=> 'http://api.myspace.com/request_token',
			authorization_url 	=> 'http://api.myspace.com/authorize',
			access_token_url 	=> 'http://api.myspace.com/access_token',
		},
	);
	
	return bless $self, $class;

}

sub oauth { $_[0]->{'oauth'} }

=head1 API Resources

The following methods are implemented on this version of C<Net::MySpace>:

=cut

=head2 Activities

C<http://wiki.developer.myspace.com/index.php?title=MySpace_REST_Resources#Activities>

=head3 activities

Required parameters: C<userId>.

=cut

=head3 friends_activities

Required parameters: C<userId>.

=cut

=head2 Albums

C<http://wiki.developer.myspace.com/index.php?title=MySpace_REST_Resources#Albums>

=head3 albums

Required parameters: C<userId>.

=cut

=head3 album

Required parameters: C<userId>, C<albumId>.

=cut

=head3 album_photos

Required parameters: C<userId>, C<albumId>.

=cut

=head2 Friends

C<http://wiki.developer.myspace.com/index.php?title=MySpace_REST_Resources#Friends>

=head3 verify_friendship

Required parameters: C<userId>, C<friendsId>.

=cut

=head3 friends_status

Required parameters: C<userId>.

=cut

my $api_def = {
	
	###
	### activities
	###


	'activities' => {
		resource => '/:version/users/:userId/activities',
		format => 'atom',
		method => 'GET',
		api_name => 'GET_v1_users_userId_activities',
	},



	'friends_activities' => {
		resource => '/:version/users/:userId/friends/activities',
		format => 'atom',
		method => 'GET',
		api_name => 'GET_v1_users_userId_friends_activities',
	},



	'albums' => {
		resource => '/:version/users/:userId/albums',
		method => 'GET',
		api_name => 'GET_v1_users_userId_albums',
	},



	'album' => {
		resource => '/:version/users/:userId/:albumId',
		method => 'GET',
		api_name => 'GET_v1_users_userId_albums_albumId',
	},


	'album_photos' => {
		resource => '/:version/users/:userId/albums/:albumId/photos',
		method => 'GET',
		api_name => 'GET_v1_users_userId_albums_albumId_photos',
	},




	'verify_friendship' => {
		resource => '/:version/users/:userId/friends/:friendsId',
		method => 'GET',
		api_name => 'GET_v1_users_userId_friends_friendsId',
	},
	
	
	

	'friends_status' => {
		resource => '/:version/users/:userId/friends/status',
		method => 'GET',
		api_name => 'GET_v1_users_userId_friends_status',
	},
	'friends' => {
		resource => '/:version/users/:userId/friends',
		method => 'GET',
		api_name => 'GET_v1_users_userId_friends_list_page_show',
		optional_parameters => [qw/list page page_size show/]
	},
	
	###
	### profile
	###
	
	'profile' => {
		resource => '/:version/users/:userId/profile',
		method => 'GET',
		api_name => 'GET_v1_users_userId_profile_basic_full_extended',
		optional_parameters => [qw/detailtype/]
	}, # meaning users.userId
	'basic_profile' => {
		resource => '/:version/users/:userId',
		method => 'GET',
		api_name => 'GET_v1_users_userId',
	},
	'detailed_profile' => {
		resource => '/:version/users/:userId/details',
		method => 'GET',
		api_name => 'GET_v1_users_userId_details',
	},
	'profile_comments' => {
		resource => '/:version/users/:userId/comments',
		method => 'GET',
		api_name => 'GET_v1_users_userId_comments',
	},
	
	###
	### user
	###
	
	'user' => {
		resource => '/:version/user',
		method => 'GET',
		api_name => 'GET_v1_user',
	},
};

while(my($k, $v) = each %$api_def) {
	no strict 'refs';
		
	*{__PACKAGE__ . "::$k"} = sub {
		my $self = shift;
		my %args = @_;
		my $j = JSON::Any->new;
		
		my $url = $API_URL.$v->{resource};
		
		# replace version
		$url =~ s/:version/$API_VERSION/;
		$url .= ".$API_FORMAT" if $API_FORMAT;
		
		my(@params) = $url =~ /:(\w+)/g;
		
		for my $p (@params) {
			croak "Missing parameter: $p" unless exists $args{$p}; 
			$url =~ s/:$p/$args{$p}/;
		}
		
		$j->jsonToObj(
			$self->oauth->make_restricted_request($url, $v->{method})->decoded_content
		);
	}
}


1;