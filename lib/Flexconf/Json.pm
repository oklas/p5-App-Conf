package Flexconf::Json;

use JSON::MaybeXS;

sub parse {
  return decode_json shift;
}

sub stringify {
  return encode_json shift;
}

sub load {
   my ( $filepath ) = @_;
   local $/;
   open FH, "<", $filepath or die("Could not load '$filepath' $!");
   my $conf = <FH>;
   $conf = decode_json $conf;
   close FH;
   $conf;
}

sub save {
   my ( $filepath, $conf ) = @_;
   open FH, ">", $filepath or die("Could not save '$filepath' $!");
   print FH encode_json $conf;
   close FH;
}

sub stringify_pretty {
  JSON::MaybeXS->new->pretty(1)->utf8->allow_nonref->
    space_before(0)->space_after(1)->encode(shift)
}

1;

