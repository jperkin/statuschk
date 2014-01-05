package StatusChk::ping;

use Net::Ping;

$max_run_time = 10;

sub check
{
  my ($svc) = @_;

  my $host = $svc->{args};

  my $ping = new Net::Ping("icmp");
  my $res = $ping->ping($host, 5);
  $ping->close;

  if (!defined $res)
  {
    return("ERROR", "Ping failed");
  }
  elsif ($res == 1)
  {
    return ("UP",undef);
  }
  else
  {
    return ("DOWN","$host not responding");
  }
}

1;
