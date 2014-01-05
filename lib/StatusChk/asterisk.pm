package StatusChk::asterisk;

use Carp;
use IO::Socket;
use IO::Select;

$max_run_time = 30;

sub check
{
  my ($svc) = @_;

  my ($host, $user, $pass) = split / /, $svc->{args}, 3;

  my $sock = new IO::Socket::INET(
			PeerAddr => $host,
			PeerPort => "5038",
			Proto => 'tcp',
			Timeout => 10);

  if (!defined $sock)
  {
    return ("DOWN", $!);
  }

  my $line = <$sock>;
  $line =~ s/[\r\n]+$//;

  my @login = send_command ( $sock, 
        Action   => 'Login',
        Username => $user,
        Secret   => $pass,
        Events   => 'off'
  );
  if ( ($login[0]{'Response'} ne 'Success') ) 
  {
        return("DOWN", "Authentication failed for user $user");
  };

  my @ping = send_command($sock, Action => 'Ping' );
  if ( ($ping[0]{'Response'} ne 'Pong')  && ($ping[0]{'Response'} ne 'Success'))
  {
    return("DOWN", "Incorrect Ping response: ".$ping[0]{'Response'});
  };

  $sock->close;

  return("UP", undef);
}

sub send_command
{
  my ($sock, %command) = @_;

  my $cstring = h2s(%command);
  print $sock "$cstring\r\n";

  return read_response($sock);
};

sub read_response
{
  my ($sock) = @_;
  my @response;
  while (1)
  {
    my %group = read_group($sock);
    push @response, \%group;
    last if $group{'Response'};
  };
  return @response;
};

sub read_group
{
  my ($sock) = @_;
  my @group;
  while (my $line = <$sock>)
  {
    $line =~ s/[\r\n]*//g;
    last if ($line eq '');
    push(@group, split(':\s*', $line)) if $line;
  };
  return @group;
};

sub h2s
{
  my (%thash) = @_;
  my $tstring = '';
  foreach my $key (keys %thash)
  {
    $tstring .= sprintf "%s: %s\r\n", $key, $thash{$key};
  };
  return $tstring;
};

1;
