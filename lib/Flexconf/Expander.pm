package Flexconf::Expander;

=head1 NAME

Flexconf - Configuration files management library and program

=head1 SYNOPSIS

    use Flexconf;
    use Flexconf::Expander;

    my $conf = Flexconf->new();
    $conf->data({
      k = 'uniq',
    })

    my $data =  {
      k1 => '${HOME}',
      k2 => '${TASK:-task1}',
      k3 => 'a.$[k].b',
    }

    my $exp = Flexconf::Expander->new(
      $flexconf # optional if $[...] is absent
    );

    # data chaned inplace, deep copy does not performed:

    $data = $exp->expand( $data )

    # data now is:
    {
      k1 => '/home/user',
      k2 => 'task1',
      k3 => 'a.uniq.b',
    }

=cut

use strict;
use warnings;

sub new {
  my ($package, $flexconf) = @_;
  bless {
    conf => $flexconf,
  }, $package;
}


sub error {
  my ($self, $error) = @_;
  if( 2 == scalar @_ ) {
    $self->{error} = "$error at flexconf line $self->{line}";
  } else {
    return $self->{error};
  }
}


sub expand_variable_chunk {
  my ($self, $chunk) = @_;

  my ($open) = $chunk =~ /^(.)/;
  my $close = {
    '[' => ']',
    '{' => '}',
  }->{$open};

  return $self->error("wrong brace '$open' for \$ '$chunk'") unless $close;
  my ( $expand, undef, $tail ) = $chunk =~ /[\[\{]([^$close]+)([\]\}]?)(.*)/;
  return $self->error("unmatched brace '$open'") unless $2;
  my ( $var, $def ) = split ':', $expand;
  return $self->error("unable expand flexpath '$var' without flexconf")
    if( !$self->{conf} and $open eq '[' );

  my $value = {
    '[' => sub{ $self->{conf}->get($_[0]) },
    '{' => sub{ $ENV{($_[0])} },
  }->{$open}->($var);

  my ($defop, $defval) = $def ? $def =~ /^(.)(.*)$/ : ($def);

  $value = !length($def) ? $value : ({
      '+' => sub{ length($_[0]) ? $_[1] : $_[0] },
      '-' => sub{ length($_[0]) ? $_[0] : $_[1] },
    }->{$defop} || sub{$self->error("wrong operator '$defop' in expand")}
  )->($value, $defval);

  $value . $tail
}


sub expand_variables {
  my ($self, $arg) = @_;
  return $arg unless $arg;
  my @chunks = split /\$/, $arg;
  my $result = $arg =~ /^\$/ ? '' : shift @chunks;
  $result .= join '', map {
    $self->expand_variable_chunk($_)
  } grep{ length } @chunks;
  return '' if $self->error;
  $result
}

sub expand {
  my ($self, $var) = @_;
  if( 'HASH' eq ref $var ) {
    map { $var->{$_} = $self->expand($var->{$_}) }
    grep { !$self->error }
    keys %{$var};
  } elsif ( 'ARRAY' eq ref $var ) {
    map { $var->[$_] = $self->expand($var->[$_]) }
    grep { !$self->error }
    0..$#{$var};
  } else {
    return $self->expand_variables($var);
  }
  return $var;
}

1;

__END__

=head1 See Also

Flexconf core: L<Flexconf>.

=head1 LICENSE

Copyright (C) Serguei Okladnikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Serguei Okladnikov E<lt>oklaspec@gmail.comE<gt>

=cut
