#
# Use the RFC 2326 required OPTIONS command to check
# on the status of a compliant RTSP server, such as
# the Edgeware Orbit. 
#

package StatusChk::rtsp;

use Carp;
use IO::Socket;

$max_run_time = 30;

sub check
{
  my ($svc) = @_;

  my ($host) = $svc->{args};

  my $sock = new IO::Socket::INET(
			PeerAddr => $host,
			PeerPort => "554",
			Proto => 'tcp',
			Timeout => 10);

  if (!defined $sock)
  {
    return ("DOWN", $!);
  }

  print $sock "OPTIONS * RTSP/1.0\r\n";
  print $sock "CSeq: 1\r\n";
  print $sock "Require: implicit-play\r\n";
  print $sock "Proxy-Require: gzipped-messages\r\n";
  print $sock "\r\n";

  my $resp = <$sock>;
  $sock->close();

  if ($resp =~ /200/) 
  { 
    return ("UP");
  }
  return ("DOWN");
}

1;
