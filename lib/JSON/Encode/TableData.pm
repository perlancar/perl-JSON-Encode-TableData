package JSON::Encode::TableData;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;
use JSON::MaybeXS ();

use Exporter qw(import);
our @EXPORT_OK = qw(encode_json);

sub encode_json {
    my $input = shift;

    # BEGIN copy-pasted from App::td with some modification
    # give envelope if not enveloped
    my $envelope_added;
    unless (ref($input) eq 'ARRAY' &&
                @$input >= 2 && @$input <= 4 &&
                $input->[0] =~ /\A[2-5]\d\d\z/ &&
                !ref($input->[1])
            ) {
        $envelope_added++;
        $input = [200, "Envelope added by ".__PACKAGE__, $input];
    }

    require Data::Check::Structure;
    if (ref($input->[2]) eq 'HASH') {
        # XXX currently we don't support this
        goto ENCODE_DIRECTLY;
    } elsif (Data::Check::Structure::is_aos($input->[2])) {
        goto ENCODE_AND_FORMAT;
    } elsif (Data::Check::Structure::is_aoaos($input->[2])) {
        goto ENCODE_AND_FORMAT;
    } elsif (Data::Check::Structure::is_aohos($input->[2])) {
        goto ENCODE_AND_FORMAT;
    } else {
        goto ENCODE_DIRECTLY;
    }

  ENCODE_AND_FORMAT: {
        require UUID::Random;
        my $encoder = JSON::MaybeXS->new(allow_nonref=>1);

        my $tag = UUID::Random::generate();
        my $rows = $input->[2];
        $input->[2] = $tag;

        my $res_main = $encoder->encode($input);
        my $res_array = "[\n";
        for my $i (0..$#{$rows}) {
            $res_array .= "   ".$encoder->encode($rows->[$i]).($i == $#{$rows} ? "" : ",")."\n";
        }
        $res_array .= "]";
        $res_main =~ s/"$tag"/$res_array/;
        return $res_main;
    }

  ENCODE_DIRECTLY:
    {
        return JSON::MaybeXS::encode_json($envelope_added ? $input->[2] : $input);
    }
}

1;
# ABSTRACT: Encode table data to JSON (put each row on its own line)

=head1 SYNOPSIS

 use JSON::Encode::TableData qw(encode_json); # not exported automatically
 say encode_json([200, "OK", [{rownum=>1, a=>"one"}, {rownum=>2, a=>"two"}, {rownum=>3, a=>"three"}]]);

Sample output:

 [200,"OK",[
    {rownum=>1, a=>"one"},
    {rownum=>2, a=>"two"},
    {rownum=>3, a=>"three"},
 ]


=head1 DESCRIPTION

This is a JSON encoder specifically for I<table data> (consult L<td> from
L<App::td> to read more about table data). Its goal is to display each table row
on a separate line for ease of grepping.


=head1 FUNCTIONS

=head2 encode_json


=head1 SEE ALSO

L<JSON::MaybeXS> and a plethora of other JSON encoders.

L<td> from L<App::td> to read more about I<table data>.
