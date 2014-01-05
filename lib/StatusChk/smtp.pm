package StatusChk::smtp;

use Carp;
use IO::Socket;
use IO::Select;

$max_run_time = 30;

sub check
{
  my ($svc) = @_;

  my ($host) = $svc->{args};

  my $sock = new IO::Socket::INET(
			PeerAddr => $host,
			PeerPort => "smtp(25)",
			Proto => 'tcp',
			Timeout => 10);

  if (!defined $sock)
  {
    return ("DOWN", $!);
  }

  my $rin = new IO::Select;
  $rin->add($sock);

  my ($nfound) = IO::Select->select($rin, undef, undef, 10);
  if (scalar(@$nfound) == 0)
  {
    return("DOWN", "No response");
  }

  my $line = <$sock>;
  $line =~ s/[\r\n]+$//;

  my ($status, $rest) = ($line =~ /^(\d\d\d)\s*(.*)$/);

  print $sock "QUIT\r\n";
  $sock->close;

  if (!defined $status || !defined $rest)
  {
    return("DOWN", "Unparsable status line: $line");
  }

  if ($status == 220)
  {
    return("UP", $rest);
  }
  else
  {
    return("DOWN", $rest);
  }
}

1;
