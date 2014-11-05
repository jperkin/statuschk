package StatusChk::ssl;

use IO::Socket;
use Net::SSLeay;
use Time::Local;
use Data::Dumper;

use Carp;

sub check
{
  my ($host) = @_;

  Net::SSLeay::randomize();
  Net::SSLeay::load_error_strings();
  Net::SSLeay::ERR_load_crypto_strings();
  Net::SSLeay::SSLeay_add_ssl_algorithms();

  my $sock = IO::Socket::INET->new(PeerAddr => $host, PeerPort => 443, Proto => 'tcp') or die "ERROR: cannot create socket";
  my $ctx = Net::SSLeay::CTX_new() or die "ERROR: CTX_new failed";
  Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL);
  my $ssl = Net::SSLeay::new($ctx) or die "ERROR: new failed";
  Net::SSLeay::set_fd($ssl, fileno($sock)) or die "ERROR: set_fd failed";
  Net::SSLeay::set_tlsext_host_name($ssl, $host) or die "ERROR: set server name failed";
  Net::SSLeay::connect($ssl) or die "ERROR: connect failed";
  my $x509 = Net::SSLeay::get_peer_certificate($ssl);
 
  my $expiry = _asn1t2t(Net::SSLeay::X509_get_notAfter($x509));

  if ($expiry <= time)
  {
    return ("DOWN", "SSL Cert expired at ".Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($x509)));
  }

  if ($expiry <= (time + (7*24*60*60)))
  {
    my $tleft = $expiry - time;

    my $left = "";
    if ($tleft > 24*60*60)
    {
      $left = sprintf("%dd ", int($tleft / (24*60*60)));
      $tleft = $tleft % (24*60*60);
    }
    $left .= sprintf("%dh %dm", int($tleft / (60*60)), 
		int($tleft / 60) % 60);
 
    return ("WARN", "SSL Cert expires in ".$left);
  }

  return ("UP", undef);
}

sub _asn1t2t {
    my %mon2i = qw(
        Jan 0 Feb 1 Mar 2 Apr 3 May 4 Jun 5 
        Jul 6 Aug 7 Sep 8 Oct 9 Nov 10 Dec 11
    );

    my $t = Net::SSLeay::P_ASN1_TIME_put2string( shift );

    my ($mon,$d,$h,$m,$s,$y) = split(/[\s:]+/,$t);
    defined( $mon = $mon2i{$mon} ) or die "invalid month in $t";
    my $tz = $y =~s{^(\d+)([A-Z]\S*)}{$1} && $2;
    if ( ! $tz ) {
        return timelocal($s,$m,$h,$d,$mon,$y)
    } elsif ( $tz eq 'GMT' ) {
        return timegm($s,$m,$h,$d,$mon,$y)
    } else {
        die "unexpected TZ $tz from ASN1_TIME_print";
    }
}

1;
