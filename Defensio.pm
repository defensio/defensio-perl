package Defensio;

use Carp;
use LWP::UserAgent;
use Badger::Codec::URI;
use JSON::XS;
use strict;

# You shouldn't modify these values unless you really know what you are doing. And then again...
my $API_VERSION   = '2.0';
my $API_HOST      = "http://api.defensio.com";

# You should't modify anything below this line.
my $LIB_VERSION   = "0.9";
my $ROOT_NODE     = "defensio-result";
my $FORMAT        = "json";
my $USER_AGENT    = "Defensio-Perl 0.9";
my $CLIENT        = 'Defensio-Perl | 0.9 | Jason Pope | jpope@websense.com';



    my $ua; 
    my $codec ;
    
sub new{
  my ($class, %params) = @_;

  $ua = LWP::UserAgent->new;
  $ua->agent($USER_AGENT);
   $ua->timeout(30);
   
   $codec =  Badger::Codec::URI->new();

  return undef unless $params{api_key};

  my $this=
  {
    'api_key'        => $params{'api_key'},
    'client'         => $params{'client'} || $CLIENT,
    'format'         => $params{'format'} || 'json',
    'service_type'   => $params{'service_type'} || 'app',
    'protocol'       => $params{'protocol'} || 'http',
    'platform'       => $params{'platform'} || 'defensio-perl',
    'port'           => $params{'port'} || 80,
    'async'          => $params{'async'} || 'true',
    'async-callback' => $params{'async-callback'},
  };

  bless ($this, $class);
  return $this;
}

# Get information about the api key
sub get_user{
  my $this = shift;
  $this->call('get',$this->api_url );
}

# Create and analyze a new document
# @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
# @return [Hash] the values returned by Defensio
sub post_document{
  my ($this, %data) = @_;
  return $this->call ('post', $this->api_url("documents"), \%data);
}
# Get the status of an existing document
# @param [String] signature The signature of the document to modify
# @return [Hash] the values returned by Defensio
sub get_document{
  my ($this, $signature) = @_;
  $this->call ('get', $this->api_url("documents", $signature));
}

# Modify the properties of an existing document
# @param [String] signature The signature of the document to modify
# @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
# @return [Hash]  the values returned by Defensio
sub put_document{
  my ($this,$signature, %data) = @_;
  return $this->call ('put', $this->api_url("documents", $signature), \%data);
}

# Get basic statistics for the current user
# @return [Hash] the values returned by Defensio
sub get_basic_stats{
  my $this = shift;
  return $this->call ('get', $this->api_url("basic-stats"));
}

# Get more exhaustive statistics for the current user
# @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
# @return [Hash] the values returned by Defensio
sub get_extended_stats{
  my ($this, %data) = @_;
  return $this->call('get', $this->api_url("extended-stats"), \%data);
}

# Filter a set of values based on a pre-defined dictionary
sub post_profanity_filter{
    my ($this, %data) = @_;
    return $this->call ('post', $this->api_url("profanity-filter"), \%data);
}

sub call{
  my ($this, $method, $url, $data) = @_;
  my $response, $data;
  my $postdata = '';


  foreach my $key ( keys %{$data} )
  {
     $postdata .= "$key=" .$codec->encode($data->{$key})."&";
   }
  foreach my $key ( keys %{$this} )
  {
    $postdata .= "$key=$this->{$key}&";
  }

  if(lc($method) =~ /get|delete|post|put/){
    $response = $this->http_request(uc($method), $url, $postdata);
  } 
  else{
    $response = undef;
    confess ("ArgumentError: Invalid HTTP method: $method");
  }

  if( $response =~ m/{.*}/)
  {
    $data = decode_json($response);
    if($data->{$ROOT_NODE}->{status} =~ /fail/)
    {
        confess ("Request Failed: " . $data->{$ROOT_NODE}->{message}); 
    }
    return $data->{$ROOT_NODE};
  }
  confess("Invalid Response: $response");
  return undef;
}

sub http_request{
  my ($this, $method,$url, $data) = @_;
  my $response;
  
  $url .= $data if(lc($method) =~ /put/);
  my $req = HTTP::Request->new($method => $url);
  $req->content($data) if $data;
  $response = $ua->request($req);
  
  return  $response->content;
}

sub api_url{
  my ($this, $action, $id) = @_;
  my $path = "$API_HOST/$API_VERSION/users/$this->{api_key}";
  $path .= "/$action" if $action;
  $path .= "/$id" if $id;
  $path .= ".$FORMAT";
  return $path;
}

1;