package Flexconf;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

Flexconf - Configuration files management library and program

Currently this module API and CLI is subject to change.

Any suggestions or bugreports are appreciated at issue tracker.
Show your support and acceptance of package and ideas by starring.
Please visit https://github.com/oklas/flexconf for that.

=head1 SYNOPSIS

    use Flexconf;

    my $conf = Flexconf->new({k=>'v',...} || nothing)

    # parse or stringify, format: 'json'||'yaml'
    $conf->parse(format => '{"k":"v"}')
    $string = $conf->stringify('format')

    # save or load, format (may be ommitted): 'auto'||'json'||'yaml'
    $conf->load('app.module', format => $filename)
    $conf->save('app.module', firmat => $filename)
    $conf->load('app.module', $filename) # autodetect format by file ext
    $conf->save('app.module', $filename) # autodetect format by file ext

    # replace whole tree
    $conf->put('',{k=>'v'...})
    $conf->put('.',{k=>'v'...})

    # access to root of conf tree
    $root = $conf->get
    $root = $conf->get '' # or '.'

    # access to subtree in depth by path
    $module_conf = $conf->get('app.module')

    # assign subtree in depth by path
    $conf->put('h', {a=>[]})
    $conf->put('h.a.0', [1,2,3])
    $conf->put('h.a.0.2', {k=>'v'})

    # copy subtree to another location
    $conf->copy('to', 'from')
    $conf->copy('k.a', 'h.a.0')

    # move subtree
    $conf->move('k.a', 'h.a.0')

    # remove subtree by path
    $conf->remove('k.v')

    # methods, which return conf itself:
    # load, save, asign, copy, move, remove

=head1 DESCRIPTION

Flexconf is base for configuration management

=cut


use Storable qw[dclone];

use Flexconf::Json;
use Flexconf::Yaml;

sub new {
  my ($package, $data) = @_;
  my $self = bless {data => $data}, $package;
}

sub data {
  my ($self, $data) = @_;

  return $self->{data} if 1 == scalar @_;

  my $prev_data = $self->{data};
  $self->{data} = $data;
  return $prev_data;
}


sub _namespace {
  my ($self, $type) = @_;
  return 'Flexconf::Json' if 'json' eq $type;
  return 'Flexconf::Yaml' if 'yaml' eq $type;
  die 'wrong conf format'
}


sub type_by_filename {
  my ($self, $filename) = @_;
  return 'json' if $filename =~ /\.json$/;
  return 'yaml' if $filename =~ /\.yaml$/;
  return 'yaml' if $filename =~ /\.yml$/;
  die 'unable to dermine conf format by filename'
}


sub stringify {
  my ($self, $type) = @_;
  my $namespace = $self->_namespace($type);
  return (\&{"${namespace}::stringify"})->($self->data);
}


sub parse {
  my ($self, $type, $string) = @_;
  my $namespace = $self->_namespace($type);
  $self->data((\&{"${namespace}::parse"})->(), $string);
}


sub save {
  my ($self, $path, $type, $filename) = @_;
  if( 3 == scalar @_ ) {
    $filename = $type;
    $type = 'auto';
  }
  $type = $self->type_by_filename($filename) if $type eq 'auto';
  my $namespace = $self->_namespace($type);
  my $data = $self->get($path);
  (\&{"${namespace}::save"})->($filename, $data);
  $self;
}


sub load {
  my ($self, $path, $type, $filename) = @_;
  if( 3 == scalar @_ ) {
    $filename = $type;
    $type = 'auto';
  }
  $type = $self->type_by_filename($filename) if $type eq 'auto';
  my $namespace = $self->_namespace($type);
  $self->put($path, (\&{"${namespace}::load"})->($filename) );
  $self;
}


sub path_to_array {
  my ($self, $path) = @_;
  $path = $self if 1 == scalar @_;
  $path = $path || '';
  $path = [split(/\./, $path)] if 'ARRAY' ne ref $path;
  return $path;
}


sub path_to_str {
  my ($self, $path) = @_;
  $path = $self if( 1 == scalar @_ );
  return 'ARRAY' eq ref $path ? join('.', @$path) : $path
}


sub reserve {
  my ($self, $path) = @_;
  $path = path_to_array($path);
  my $data = $self->data;
  if(not defined $data) {
    $self->data({});
    $data = $self->data;
  }
  for(@$path) {
    if('ARRAY' eq ref $data) {
      unless(/^\d+$/) {
        die "unable to access array element by key '$_' ".
          "in path: '".path_to_str($path)."'";
      }
      $data->[$_] = {} unless exists $data->[$_];
      $data = $data->[$_];
      next;
    }
    if('HASH' eq ref $data) {
      $data->{$_} = {} unless exists $data->{$_};
      $data = $data->{$_};
      next;
    }
    die "only hash or array must be parent for key '$_' ".
      "in path: '".path_to_str($path)."'";
  }
  return $data;
}


*fetch = \&get;
sub get {
  my ($self, $path) = @_;
  $path = path_to_array($path);
  my $data = $self->data;
  for(@$path) {
    unless( defined $data ) {
      return undef unless $self->{strict};
      die "unable to access by key '$_' ".
        "when data is neither hash nor array for path: '".
        path_to_str($path)."'";
    }
    if( 'HASH' eq ref($data) ) {
      $data = $data->{$_};
      next;
    }
    if( 'ARRAY' eq ref($data) ) {
      unless( /^\d+$/ ) {
        die "unable to access to array by index '$_' in path: '".
          path_to_str($path)."'";
      }
      $data = $data->[$_];
      next;
    }
    $data = undef;
  }
  return $data;
}


*assign = \&put;
sub put {
  my ($self, $path, $data) = @_;
  my $path_pre = $self->path_to_array($path);
  my $key_pre = pop @$path_pre;
  if( !defined $key_pre || $key_pre eq '' ) {
    $self->data($data);
    return $self;
  }
  my $data_pre = $self->reserve($path_pre);
  if( 'HASH' eq ref $data_pre ) {
    $data_pre->{$key_pre} = $data;
    return $self;
  }
  if( 'ARRAY' eq ref $data_pre ) {
    unless( $key_pre =~ /^\d+$/ ) {
      die "unable to assign array item by index '$key_pre' in path: '".
        path_to_str($path)."'";
    }
    $data_pre->[$key_pre] = $data;
    return $self;
  }
  die "unable to assign to '".(ref($data_pre)||'nonref').
    "' by index '$key_pre' in path: '".path_to_str($path)."'";
}


*rm = \&remove;
sub remove {
  my ($self, $path) = @_;
  my $path_pre = $self->path_to_array($path);
  my $key_pre = pop @$path_pre;
  if( !defined $key_pre || $key_pre eq '' ) {
    $self->data(undef);
    return $self;
  }
  my $data_pre = $self->get($path_pre);
  if( 'HASH' eq ref $data_pre ) {
    delete $data_pre->{$key_pre};
    return $self;
  }
  if( 'ARRAY' eq ref $data_pre ) {
    unless( $key_pre =~ /^\d+$/ ) {
      die "unable to remove array item by index '$key_pre' in path: '".
      path_to_str($path)."'";
    }
    splice @$data_pre, $key_pre, 1;
    return $self;
  }
  die "unable to remove from '".(ref($data_pre)||'nonref').
    "' by index '$key_pre' in path: '".path_to_str($path)."'";
}


*cp = \&copy;
sub copy {
  my ($self, $path_to, $path_from) = @_;
  my $path_preto = $self->path_to_array($path_to);
  my $key_to = pop @$path_preto;
  my $data = $self->get($path_from);
  if( grep {$_ eq ref $data} ('HASH', 'ARRAY') ) {
    $data = dclone $data;
  }
  if( !defined $key_to || $key_to eq '' ) {
    $self->data($data);
    return $self;
  }
  my $data_to = $self->get($path_preto);
  if( 'HASH' eq ref $data_to ) {
    $data_to->{$key_to} = $data;
    return $self;
  }
  if( 'ARRAY' eq ref $data_to ) {
    unless( $key_to =~ /^\d+$/ ) {
      die "unable to assign to array by index '$key_to' in path: '".
        path_to_str($path_to)."'";
    }
    $data_to->[$key_to] = $data;
    return $self;
  }
  die "unable to assign to '".(ref($data_to)||'nonref').
    "' by index '$key_to' in path: '".path_to_str($path_to)."'";
}


*mv = \&move;
sub move {
  my ($self, $path_to, $path_from) = @_;
  my $data = $self->get($path_from);
  $self->remove($path_from);
  $self->assign($path_to, $data);
  $self;
}


1;
__END__

=head1 LICENSE

Copyright (C) Serguei Okladnikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Serguei Okladnikov E<lt>oklaspec@gmail.comE<gt>

=cut

