package StatusChk::http;

use LWP;
use Carp;

$max_run_time = 30;

sub check
{
  my ($svc) = @_;

  my ($url) = $svc->{args};

  my $ua = new LWP::UserAgent;
  $ua->agent("StatusChk::http");
  $ua->timeout(60);

  my $req = new HTTP::Request('GET', $url);
  my $res = $ua->request($req);

  if ($res->is_success || $res->code == 302)
  {
    return("UP",undef);
  }
  else
  {
    if ($res->code == 602)
    {
      $res->content =~ m/<PRE>(.*)<\/PRE>/s;
      my @lines = split(/\n/, $1);
      my $error = $lines[3];
      return ("DOWN","$error");
    }
    else
    { 
      return("DOWN", $res->code." ".$res->message);
    }
  }

}

1;
