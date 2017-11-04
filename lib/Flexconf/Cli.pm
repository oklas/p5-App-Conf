package Flexconf::Cli;

=head1 NAME

Flexconf command line interface implementation

=head1 SYNOPSIS

    Flexconf::Cli::main @ARGV;

=cut


use Pod::Usage;

use Flexconf;
use Flexconf::Processor;


sub usage {
  Pod::Usage::pod2usage(0)
}


sub main {
  my @argv = @_;

  return usage unless @argv;

  my %opts = @argv;
  my %known; @known{ qw[-t -c -f] } = ();

  return usage unless grep{exists $known{$_}} keys %opts;

  my $conf = Flexconf->new({});

  if( $opts{-c} ) {
    if( $opts{-t} ) {
      $conf->load( '.', $opts{-t}, $opts{-c} );
    } else {
      $conf->load( '.', $opts{-c} );
    }
  }

  if( $opts{-f} ) {
    my $processor = Flexconf::Processor->new($conf);
    $processor->eval($opts{-f});
  }
}

1;
