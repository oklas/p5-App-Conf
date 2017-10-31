package Flexconf::Processor;

use Switch;


use constant ERR  => 0;
use constant CMD  => 1;
use constant ARG  => 2;
use constant JSON => 3;

sub new {
  my ($package, $flexconf) = @_;
  bless { conf => $flexconf }, $package;
}

sub cmd_hash {
  my @cmds = qw[
    on alias load save get assign remove copy
  ];
  my %cmds;
  map{ $cmds{$_} = {} } @cmds;
  $cmds{assign} = {json_arg=>2};
  return \%cmds;
}

sub init {
  my ($self, $string) = @_;
  $self->{lexems} = [ split/([;\n\s])/mig, $string ];
  $self->{stmt} = [];
  $self->{stmt_list} = [];
  $self->{state} = CMD;
  $self->{error} = '';
  $self->{on} = '';
  $self->{line} = 1;
}

sub error {
  my ($self, $error) = @_;
  if( 2 == scalar @_ ) {
    $self->{error} = "$error at line $self->{line}";
    $self->{state} = ERR;
  } else {
    return $self->{error};
  }
}

sub stmt_init {
  my ($self) = @_;
  $self->{stmt} = [];
  $self->{on} = '';
}

sub stmt_done {
  my ($self) = @_;
  push @{ $self->{stmt_list} }, $self->{stmt};
  $self->stmt_init;
}

sub stmt_push {
  my ($self, $tok) = @_;
  push @{ $self->{stmt} }, $tok;
}

sub current_cmd {
  my ($self) = @_;
  unless( @{ $self->{stmt} } ) {
    die "current cmd unknown due to stmt empty";
  }
  return $self->{stmt}->[0];
}

sub current_arg_num {
  my ($self) = @_;
  return -1 + @{ $self->{stmt} };
}

sub current_arg_type {
  my ($self) = @_;
  my $cmd = $self->current_cmd();
  my $num = cmd_hash->{$cmd}->{json_arg};
  return JSON if( $num == $self->current_arg_num );
  return ARG;
}

sub is_space {
  my $tok = shift;
  $tok =~ /^\s+$/;
}

sub is_delim {
  my $tok = shift;
  $tok =~ /^[;\t]+$/;
}

sub is_cmd {
  my $tok = shift;
  my $cmds = cmd_hash;
  exists $cmd->{$tok};
}

sub lex {
  my ($self) = @_;
  if( JSON == $self->{state} ) {
    return $self->lex_json;
  }
  my $tok = shift @{ $self->{stmt_list} };
  $self->{line}++ if $tok eq "\n";
  $tok;
}

sub lex_json {
}

sub parse {
  my ($self, $string) = @_;
  my $on;
  my @stmt;
  $self->init( $string );
  while( my $tok = $self->lex ) {
    switch( $state ) {
      case ( ERR ) { return $self->{error}; }
      case ( CMD ) { $self->tok_cmd( $tok ); }
      case ( ARG ) { $self->tok_arg( $tok ); }
      case ( JSON ) { $self->tok_json( $tok ); }
    }
  }
}

sub tok_cmd {
  my ($self, $tok) = @_;
  return if( is_space($tok) );
  return if( is_delim($tok) );
  unless( is_cmd($tok) ) {
    return $self->error("command '$tok' is not exists");
  }
  $self->stmt_push($tok);
  $self->{state} = ARG;
  if( JSON == 1+$self->current_arg_type ) {
    $self->{state} = JSON;
  }
}

sub tok_arg {
  my ($self, $tok) = @_;
  return if( is_space($tok) );
  return $self->stmt_done if( is_delim($tok) );
  $self->stmt_push($tok);
}

sub tok_json {
  my ($self, $tok) = @_;
  $self->tok_arg($tok);
}

1;
