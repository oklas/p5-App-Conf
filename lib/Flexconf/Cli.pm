package Flexconf::Cli;

=head1 NAME

Flexconf command line interface implementation

=head1 SYNOPSIS

    Flexconf::Cli::main @ARGV;

=cut


use Pod::Usage;

use Flexconf;
use Flexconf::Processor;
use Flexconf::Json;


sub usage {
  Pod::Usage::pod2usage(0)
}


sub main {
  my @argv = @_;

  return usage unless @argv;

  my %opts = @argv;
  my %known; @known{ qw[-t -c -e -g -q -k] } = ();

  return usage unless grep{exists $known{$_}} keys %opts;

  my $conf = Flexconf->new({});

  if( $opts{-c} ) {
    if( $opts{-t} ) {
      $conf->load( '.', $opts{-t}, $opts{-c} );
    } else {
      $conf->load( '.', $opts{-c} );
    }
  }

  if( $opts{-e} ) {
    my $processor = Flexconf::Processor->new($conf);
    $processor->eval($opts{-e});
  }

  if( $opts{-g} ) {
    print Flexconf::Json::stringify_pretty(
      $conf->get( $opts{-g} )
    );
  }

  if( $opts{-q} ) {
    my $res = $conf->get( $opts{-q} );
    if( (grep{ $_ eq ref $res } ('HASH', 'ARRAY')) ) {
      warn "must be not a hash or an array at '$opts{-q}' to get quote\n";
      exit 255
    }
    print $res
  }

  if( $opts{-k} ) {
    my $res = $conf->get( $opts{-k} );
    if (ref($res) eq 'ARRAY') {
      print join ' ', 0 .. $#$res;
    } elsif (ref($res) eq 'HASH') {
      print join ' ', keys %$res;
    } elsif (ref($res)) {
      print ''
    }
  }
}

1;
