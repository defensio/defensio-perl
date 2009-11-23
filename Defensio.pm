package Defensio;

use LWP::UserAgent;
use JSON;

# You shouldn't modify these values unless you really know what you are doing. And then again...
my $API_VERSION   = '2.0';
my $API_HOST      = "http://elb.defensio.net";

# You should't modify anything below this line.
my $LIB_VERSION   = "0.1";
my $ROOT_NODE     = "defensio-result";
my $FORMAT        = "json";
my $USER_AGENT    = "Defensio-Perl 0.1";
my $CLIENT        = 'Defensio-Perl | 0.1 | Jason Pope | jpope@websense.com';



my $ua; 

sub new{
  my ($class, %params) = @_;

  $ua = LWP::UserAgent->new;
  $ua->agent($USER_AGENT);

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
  my $this = shift;
  my $data = {@_};
  return $this->call ('post', $this->api_url("documents"), $data);
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
  my $this = shift;
  my $signature = shift;
  my $data = {@_ };
  return $this->call ('put', $this->api_url("documents", $signature), $data);
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
  my $this = shift;
  my $data = { @_ };
  return $this->call('get', $this->api_url("extended-stats"), $data);
}

# Filter a set of values based on a pre-defined dictionary
sub post_dictionary_filter{
my $this = shift;
my $data = {@_};
return $this->call ('post', $this->api_url("dictionary-filter"), $data);
}

sub call{
  my ($this, $method, $url, $data) = @_;
  my $response;
  $url .= "?";
  foreach my $key ( keys %{$data} )
  {
    $url .= "$key=$data->{$key}&";
  }
  foreach my $key ( keys %{$this} )
  {
    $url .= "$key=$this->{$key}&";
  }

  if(lc($method) =~ /get|delete|post|put/){
    $response = $this->http_request(uc($method), $url);
  }
  else{
    $response = undef;
    warn "ArgumentError: Invalid HTTP method: $method";
  }

  if( $response =~ m/{.*}/)
  {
    my $data = undef;
    eval { $data = from_json($response); }; warn $@ if $@;
    return $data->{$ROOT_NODE};
  }
  warn "Invalid Response: $response";
  return undef;
}

sub http_request{
  my ($this, $method,$url) = @_;
  my $req = HTTP::Request->new($method => $url);
  my $response = $ua->request($req);
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