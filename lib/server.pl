use Modern::Perl;
use HTTP::Engine;
use Data::Dumper;
use Net::MySpace;
use URI::Escape;

my $engine = HTTP::Engine->new(
    interface => {
        module => 'ServerSimple',
        args   => {
            host => 'localhost',
            port =>  1984,
        },
        request_handler => sub {
			my $req = shift;
			my $params = $req->query_parameters;
			
			my $ms = Net::MySpace->new(
				consumer_key 		=> '',
				consumer_secret 	=> '',
			);
			
			my $res = HTTP::Engine::Response->new;
			
			if($params->{authed_access_token} and $params->{authed_access_token_secret}) {
				$ms->oauth->access_token($params->{authed_access_token});
				$ms->oauth->access_token_secret($params->{authed_access_token_secret});
				
				my $user = $ms->user;
				my $friends = $ms->friends(
					userId => $user->{userId},
				);
				
				my $html = qq{<h1>$friends->{count} friends!</h1>};
				
				$html .= qq{<a href="$user->{webUri}">$user->{webUri}</a>};

				
				for my $f (@{$friends->{Friends}}) {
					$html .= <<"";
						<p><a href="$f->{webUri}">$f->{webUri}<br>
						<img src="$f->{image}">
						</a>
						</p>

				}
				
				$res->body($html);
				
			} else {
			
				unless($req->cookies->{token} and $req->cookies->{token_secret}) {
					# not authenticated
					my $url = $ms->oauth->get_authorization_url(
						oauth_callback => "http://localhost:1984/"
					);
				
					$res->cookies->{token} = {
						value			=> $ms->oauth->request_token
					};
					$res->cookies->{token_secret} = {
						value 			=> $ms->oauth->request_token_secret,
					};
				
					$res->body(qq|<a href="$url">Auth here</a>.|)
				
				} else {

					$ms->oauth->request_token($req->cookies->{token}->{value}->[0]);
					$ms->oauth->request_token_secret($req->cookies->{token_secret}->{value}->[0]);
				
					my($access_token, $access_token_secret) = $ms->oauth->request_access_token;
				
					$res->status(301);
					
					$access_token = uri_escape($access_token);
					$access_token_secret = uri_escape($access_token_secret);
					
					$res->headers->header(
						'Location' => "http://localhost:1984/?authed_access_token=$access_token&authed_access_token_secret=$access_token_secret");
						
				}
			}
			
			$res
	
		}
    },
);
$engine->run;
