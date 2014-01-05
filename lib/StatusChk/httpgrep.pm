package StatusChk::httpgrep;

use LWP;
use Carp;

$max_run_time = 30;

sub check
{
  my ($svc) = @_;

  my ($url, $match) = split / /, $svc->{args}, 2;

  my $ua = new LWP::UserAgent;
  $ua->agent("StatusChk::http");
  $ua->timeout(60);

  my $req = new HTTP::Request('GET', $url);
  my $res = $ua->request($req);

  if ($res->is_success || $res->code == 302)
  {
    if ($res->content =~ /$match/)
    {
      return("UP",undef);
    }
    else
    {
      return("DOWN", "URL does not contain " . $match);
    }
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
