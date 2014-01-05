package StatusChk::tcp;

use Carp;
use IO::Socket;

$max_run_time = 30;

sub check
{
  my ($svc) = @_;

  my ($host, $port) = split /:/, $svc->{args};

  my $sock = new IO::Socket::INET(
			PeerAddr => $host,
			PeerPort => $port,
			Proto => 'tcp',
			Timeout => 10);

  if (!defined $sock)
  {
    return ("DOWN", $!);
  }

  return ("UP", "$host:$port looks ok");
}

1;
