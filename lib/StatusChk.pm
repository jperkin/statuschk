package StatusChk;

use Data::Dumper;

sub ReadConfig
{
  my ($file, $cfggrp, $cfg) = @_;

  $cfggrp = $cfgrp || [];
  $cfg = $cfg || {};

  open (CONFIG, $file) || die "Can't read config file: $!";
  my @config = <CONFIG>;
  close(CONFIG);

  my ($c, $prepend, $lineno);
  $prepend = undef;
  $default = undef;
  $lineno = 0;
  foreach $c (@config)
  {
    $lineno++;

    $c =~ s/[\r\n]+$//;
    $c =~ s/^\s+//;

    #Ignore comments and blank lines
    next if ($c =~ /^#/);
    next if ($c =~ /^\s*$/);

    $c = $prepend . " " . $c if $prepend;

    if ($c =~ /\\$/)
    {
      $c =~ s/\\$//;
      $prepend = $c;
      next;
    }
    $prepend = undef;

    my($cmd, $rest) = split(/\s+/, $c, 2);

    if ($cmd eq 'service' || $cmd eq 'aggservice' || $cmd eq 'rservice')
    {
      my ($service, $rest) = ($rest =~ m/^\s*(\S+)\s+(.*)$/);

      if (exists ($cfg->{services}->{$service}))
      {
        print STDERR "WARNING: Service '$service' redefined at $file:$lineno\n";
        delete $cfg->{services}->{$service};
      }

      if (defined $default)
      {
        $cfg->{services}->{$service} = { %$default };
      }

      $cfg->{services}->{$service}->{name} = $service;

      $cfg->{services}->{$service}->{filedef} = "$file:$lineno";
      $cfg->{services}->{$service}->{servtype} = $cmd;

      $cfg->{services}->{$service}->{group} = join(".",@$cfggrp);

      $rest =~ s/^\s+//;

      while ($rest =~ /^(\w+)=("[^"]+"|'[^']+'|\S+)/)
      {
        $var = $1;
        $val = $2;

        if ($val =~ /^"/ || $val =~ /^'/)
        {
          $val = substr($val, 1, length($val)-2);
        }

        $cfg->{services}->{$service}->{$var} = $val;

        $rest =~ s/^(\w)+=("[^"]+"|'[^']+'|\S+)//;
        $rest =~ s/^\s+//;
      }

      if ($rest ne '')
      {
        print STDERR "WARNING: unable to parse '$rest' at $file:$lineno\n";
      }

      if (!exists $cfg->{services}->{$service}->{type} || 
		!defined $cfg->{services}->{$service}->{type} ||
		$cfg->{services}->{$service}->{type} eq '')
      {
        print STDERR "WARNING: service $service has no type - dropping\n";
        delete $cfg->{services}->{$service};
      }
      elsif ($cfg->{services}->{$service}->{args} eq '')
      {
        print STDERR "WARNING: service $service has no args - dropping\n";
        delete $cfg->{services}->{$service};
      }
      elsif (!exists $cfg->{team}->{$cfg->{services}->{$service}->{team}})
      {
        print STDERR "WARNING: service $service uses unknown team ".$cfg->{services}->{$service}->{team}."\n";
      }
    }
    elsif ($cmd eq 'default')
    {
      $default = undef;

      $rest =~ s/^\s+//;

      while ($rest =~ /^(\w+)=("[^"]+"|'[^']+'|\S+)/)
      {
        $var = $1;
        $val = $2;

        if ($val =~ /^"/ || $val =~ /^'/)
        {
          $val = substr($val, 1, length($val)-2);
        }

        $default->{$var} = $val;

        $rest =~ s/^(\w)+=("[^"]+"|'[^']+'|\S+)//;
        $rest =~ s/^\s+//;
      }
      if ($rest ne '')
      {
        print STDERR "WARNING: unable to parse '$rest' at $file:$lineno\n";
      }
      print "Default: ",Dumper($default) if $debug;
    }
    elsif ($cmd eq 'include')
    {
      $cfg = &ReadConfig($rest, $cfggrp, $cfg);
    }
    elsif ($cmd eq 'group')
    {
      my ($grpnm, $grptitle) = ($rest =~ m/^\s*(\S+)\s+(.*)$/);

      my $fullgrpnm = join(".",@$cfggrp);
      push(@{$cfg->{groups}->{$fullgrpnm}->{subgroup}}, $grpnm);

      push(@$cfggrp, $grpnm);

      $fullgrpnm = join(".",@$cfggrp);
      $cfg->{groups}->{$fullgrpnm}->{title} = $grptitle;
    }
    elsif ($cmd eq 'endgroup')
    {
      my ($egrp) = ($rest =~ m/^\s*(\S+)/);
      my $grp = pop(@$cfggrp);
      print STDERR
            "WARNING: endgroup doesn't match group '$grp' at $file:$lineno\n"
            if ($grp ne $egrp);
    }
    elsif ($cmd eq 'email')
    {
      my ($team, $email) = ($rest =~ m/^\s*(\S+)\s+(.*)$/);
      if (defined $team && defined $email)
      {
        push(@{$cfg->{team}->{$team}->{email}}, split(/,\s*/,$email));
      }
    }
    elsif ($cmd eq 'pager')
    {
      my ($team, $pager) = ($rest =~ m/^\s*(\S+)\s+(.*)$/);
      if (defined $team && defined $pager)
      {
        push(@{$cfg->{team}->{$team}->{pager}}, split(/,\s*/,$pager));
      }
    }
    elsif ($cmd eq 'icon')
    {
      my ($svc, $icon) = ($rest =~ m/^\s*(\S+)\s+(.*)$/);
      $cfg->{icon}->{$svc} = $icon;
    }
    elsif ($cmd eq 'set')
    {
      my ($var, $val) = ($rest =~ m/^\s*(\S+)\s+(.*)$/);
      $cfg->{var}->{$var} = $val;
    }
    else
    {
      print STDERR
            "WARNING: Ignoring unknown config entry '$cmd' at $file:$lineno\n";
    }
  }

  return $cfg;
}

1;
