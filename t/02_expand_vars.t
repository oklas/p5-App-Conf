use strict;
use Test::More 0.98;

use_ok $_ for qw(
  Flexconf
  Flexconf::Expander
);

my $v;
my $p;

sub create {
  return Flexconf::Expander->new(
    Flexconf->new()->put('.', {
      k1 => 'v1',
      K2 => {
        K => 'V2',
      }
    })
  );
}

sub t;
sub t {
  my ( $arg, $expected, $testname ) = @_;
  my $p = create();
  is(
    $p->expand( $arg ),
    $expected,
    $testname,
  );
}

$ENV{e1} = 'g1';
$ENV{E2} = 'G2';

t 'a${e1}b', 'ag1b', 'env: one key prefix suffix';
t '${e1}b', 'g1b', 'env: one key suffix';
t 'a${e1}', 'ag1', 'env: one key prefix';
t '${e1}', 'g1', 'env: one key';

t 'a$[k1]b', 'av1b', 'flex: one key prefix suffix';
t '$[k1]b', 'v1b', 'flex: one key suffix';
t 'a$[k1]', 'av1', 'flex: one key prefix';
t '$[k1]', 'v1', 'flex: one key';

t 'a.${e1}.b', 'a.g1.b', 'env: sub key 1';
t 'a.${E2}.b', 'a.G2.b', 'env: sub key 2';
t 'a.$[k1].b', 'a.v1.b', 'flex: sub key 1';
t 'a.$[K2.K].b', 'a.V2.b', 'flex: sub key 2';

t 'a.${e1}.b.${E2}.c', 'a.g1.b.G2.c', 'env: two sub keys';
t 'a.$[k1].b.$[K2.K].c', 'a.v1.b.V2.c', 'flex: two sub keys';

$p = create();
$v = $p->expand({
  k1 => 'a.$[K2.K].b',
  k2 => [ 'a.$[K2.K].b.$[k1].c' ],
});

t $v->{k1}, 'a.V2.b', 'test hash';
t $v->{k2}->[0], 'a.V2.b.v1.c', 'test array in hash';

done_testing;


