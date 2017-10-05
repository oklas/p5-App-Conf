package Conf;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

Conf - It's new $module

=head1 SYNOPSIS

    use Conf;

=head1 DESCRIPTION

Conf is ...

=cut


use Conf::Json;
use Conf::Yaml;

sub new {
  my ($package, $data) = @_;
  my $self = bless {data => $data}, $package;
  $self->type($type|'auto');
}

sub data {
  my ($self, $data) = @_;

  return $self->{data} unless scalar @_;

  my $data = $self->{data};
  $self->{data} = $data;
  return $data;
}


sub _namespace {
  my ($self, $type) = @_;
  return 'Conf::Json' if 'json' eq $type;
  return 'Conf::Yaml' if 'yaml' eq $type;
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
  return $namespace::stringify($self->data);
}


sub parse {
  my ($self, $type, $string) = @_;
  my $namespace = $self->_namespace($type);
  $self->data($namespace::parse(), $string);
}


sub save {
  my ($self, $type, $filename) = @_;
  $type = $self->type_by_filename($filename) if $type eq 'auto';
  my $namespace = $self->_namespace($type);
  $namespace::save($filename, $self->data);
}


sub load {
  my ($self, $type, $filename) = @_;
  $type = $self->type_by_filename($filename) if $type eq 'auto';
  my $namespace = $self->type_by_filename($filename);
  $self->data( $namespace::load($filename) );
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

