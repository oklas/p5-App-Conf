package Flexconf::Processor;

use Flexconf::Commands;
use Flexconf::Expander;
use Flexconf::Json;


use constant ERR  => 0;
use constant CMD  => 1;
use constant ARG  => 2;
use constant JSON => 3;

sub new {
  my ($package, $flexconf) = @_;
  bless {
    conf => $flexconf,
    json => JSON::MaybeXS->new->allow_nonref->pretty(1)->utf8,
    expander => Flexconf::Expander->new($flexconf),
   }, $package;
}

sub cmd_hash {
  my @cmds = qw[
    on tree eval expand load save get put cp copy mv move rm remove
  ];
  my %cmds;
  map{ $cmds{$_} = {} } @cmds;
  $cmds{put} = {json_arg=>2};
  $cmds{on} = {prefix_argcnt=>1};
  $cmds{tree} = {prefix_argcnt=>1};
  return \%cmds;
}

sub init {
  my ($self, $string) = @_;
  $self->{lexems} = [ grep{length} split(/([;\n\t ])/mig, $string), ';' ];
  $self->{json}->incr_reset;
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
    $self->{error} = "$error at flexconf line $self->{line}";
    $self->{state} = ERR;
  } else {
    return $self->{error};
  }
}

sub stmt_init {
  my ($self) = @_;
  $self->{stmt} = [];
  $self->{state} = CMD;
  $self->{on} = '';
  $self->{prefix_stmt} = undef;
}

sub stmt_done {
  my ($self) = @_;
  my $stmt = [@{$self->{prefix_stmt}}, @{$self->{stmt}}];
  push @{ $self->{stmt_list} }, $stmt;
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

sub ready_arg_cnt {
  my ($self) = @_;
  return -1 + scalar @{ $self->{stmt} };
}

sub current_arg_type {
  my ($self) = @_;
  my $cmd = $self->current_cmd();
  my $num = cmd_hash->{$cmd}->{json_arg};
  my $next_arg_num = 1 + $self->ready_arg_cnt;
  return JSON if( $num == $next_arg_num );
  return ARG;
}

sub set_state_by_arg {
  my ($self) = @_;
  $self->{state} = $self->current_arg_type;
}

sub take_prefix_if_any {
  my ($self) = @_;
  my $cmd = $self->current_cmd();
  my $argcnt = cmd_hash->{$cmd}->{prefix_argcnt};
  return unless $argcnt;
  return if $argcnt != $self->ready_arg_cnt;
  my $prefix_stmt = $self->{stmt};
  $self->stmt_init;
  $self->{prefix_stmt} = $prefix_stmt;
}

sub is_space {
  my $tok = shift;
  $tok =~ /^[\t ]+$/;
}

sub is_delim {
  my $tok = shift;
  $tok =~ /^[;\n]+$/;
}

sub is_cmd {
  my $tok = shift;
  my $cmds = cmd_hash;
  exists $cmds->{$tok};
}

sub lex {
  my ($self) = @_;
  if( JSON == $self->{state} ) {
    return $self->lex_json;
  }
  my $tok = shift @{ $self->{lexems} };
  $self->{line}++ if $tok eq "\n";
  $tok;
}

sub lex_json {
  my ($self) = @_;
  my $json = $self->{json};
  my $begin;
  my $value;
  until($value || $self->error) {
    return $self->error('no more tokens during json parse')
      unless @{ $self->{lexems} };
    my $tok = shift @{ $self->{lexems} };
    if( is_space($tok) && !$begin ) { next } else { $begin = 1 }
    $value = eval { $json->incr_parse($tok); };
    $self->{line}++ if $tok eq "\n";
    return $self->error($@) if($@);
  }
  $value;
}

sub parse {
  my ($self, $string) = @_;
  my $on;
  my @stmt;
  $self->init( $string );
  my $tok;
  while( length($tok = $self->lex) ) {
    my $state = $self->{state};
    my %switch = (
      ERR () => sub { die $self->error; },
      CMD () => sub { $self->tok_cmd( $tok ); },
      ARG () => sub { $self->tok_arg( $tok ); },
      JSON() => sub { $self->tok_json( $tok ); },
    );
    $switch{$state}->();
    return $self->error if $self->error;
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
  $self->set_state_by_arg();
}

sub tok_arg {
  my ($self, $tok) = @_;
  return if( is_space($tok) );
  return $self->stmt_done if( is_delim($tok) );
  my $extok = $self->{expander}->expand_variables($tok);
  return $self->error($self->{expander}->error)
    if $self->{expander}->error;
  $self->stmt_push($extok);
  $self->set_state_by_arg();
}

sub tok_json {
  my ($self, $tok) = @_;
  $self->tok_arg($tok);
}

sub eval {
  my ($self, $string) = @_;
  my $error = $self->parse($string);
  return $error if $error;
  my $flexconf = $self->{conf};
  my $commands = Flexconf::Commands->new($flexconf);
  foreach(@{$self->{stmt_list}}) {
    my ( $method, @args ) = @{$_};
    my $result = $commands->$method($method, @args);
    if( $result && $result != $flexconf ) {
      print Flexconf::Json::stringify_pretty($result)
    }
  }
}

1;
