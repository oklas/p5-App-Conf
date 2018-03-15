package Flexconf::Commands;

use strict;
use warnings;

use Flexconf;
use Flexconf::Expander;

sub new {
  my ($package, $flexconf) = @_;
  bless {conf=>$flexconf}, $package;
}


*get = \&redirect;
*put = \&redirect;
*load = \&redirect;
*save = \&redirect;
sub redirect {
  my ($self, $cmd, @args) = @_;
  $self->{conf}->$cmd(@args);
}

*copy = \&two_args;
*move = \&two_args;
sub two_args {
  my ($self, $cmd, $to, $from) = @_;
  $self->{conf}->$cmd($to, $from);
}

*cp = \&rev_two_args;
*mv = \&rev_two_args;
sub rev_two_args {
  my ($self, $cmd, $from, $to) = @_;
  $self->{conf}->$cmd($to, $from);
}

*rm = \&remove;
sub remove {
  my ($self, $cmd, $path) = @_;
  $self->{conf}->$cmd($path);
}

sub expand {
  my ($self, $cmd, $path) = @_;
  $self->{expander} = Flexconf::Expander->new($self->{conf})
    unless $self->{expander};
  my $var = $self->{conf}->get($path);
  $var = $self->{expander}->expand($var);
  $self->{conf}->put($path, $var);
}

sub eval {
  my ($self, $cmd, $path) = @_;
  my $src = $self->{conf}->get($path);
  if('ARRAY' eq ref $src) {
    die "not a string in array to eval '$path'" if( grep{ref} @$src );
    $src = join "\n", @$src;
  }
  die "not a string to eval '$path'" if( ref($src) );
  my $processor = Flexconf::Processor->new($self->{conf});
  $processor->eval($src);
}

sub tree {
  my ($self, $prefix_cmd, $prefix_arg, $cmd, @args) = @_;
  my $fn = $prefix_cmd . '_' . $cmd;
  my $root = $self->{conf};
  my $tree = Flexconf->new($root->get($prefix_arg));
  $self->{conf} = $tree;
  eval {
    $self->$cmd($cmd, @args);
  };
  my $exception = $@;
  $root->put($prefix_arg, $tree->data);
  $self->{conf} = $root;
  die $exception if $exception;
}

1;

