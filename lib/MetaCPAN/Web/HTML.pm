package MetaCPAN::Web::HTML;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(filter_html);

use HTML::Restrict;
use HTML::Escape qw(escape_html);
use MetaCPAN::Web::HTML::CSS qw(filter_style);

sub filter_html {
    my ( $html, $data ) = @_;

    my $hr = HTML::Restrict->new(
        uri_schemes =>
            [ undef, 'http', 'https', 'data', 'mailto', 'irc', 'ircs' ],
        rules => {
            a       => [qw( href id target )],
            b       => [],
            br      => [],
            caption => [],
            center  => [],
            code    => [ { class => qr/^language-\S+$/ } ],
            dd      => [],
            div     => [ { class => qr/^pod-errors(?:-detail)?$/ } ],
            dl      => [],
            dt      => ['id'],
            em      => [],
            h1      => ['id'],
            h2      => ['id'],
            h3      => ['id'],
            h4      => ['id'],
            h5      => ['id'],
            h6      => ['id'],
            i       => [],
            li      => ['id'],
            ol      => [],
            p       => [],
            pre     => [ {
                class        => qr/^line-numbers$/,
                'data-line'  => qr/^\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$/,
                'data-start' => qr/^\d+$/,
            } ],
            span   => [ { style => qr/^white-space: nowrap;$/ } ],
            strong => [],
            sub    => [],
            sup    => [],
            table  => [ qw( border cellspacing cellpadding align ), ],
            tbody  => [],
            th     => [],
            td     => [],
            tr     => [],
            u      => [],
            ul     => [ { id => qr/^index$/ } ],
        },
        replace_img => sub {

            # last arg is $text, which we don't need
            my ( $tagname, $attrs, undef ) = @_;
            my $tag = '<img';
            for my $attr (qw( alt border height width src title)) {
                next
                    unless exists $attrs->{$attr};
                my $val = $attrs->{$attr};
                if ( $attr eq 'src' ) {
                    if ( $val =~ m{^(?:(?:https?|ftp):)?//|^data:} ) {

                        # use directly
                    }
                    elsif ( $val =~ /^[0-9a-zA-Z.+-]+:/ ) {

                        # bad protocol
                        return '';
                    }
                    elsif ($data && $data->{source_host}) {
                        my $base = $data->{source_host} . '/source/';
                        if ( $val =~ s{^/}{} ) {
                            $base .= "$data->{author}/$data->{release}/";
                        }
                        else {
                            $base .= $data->{associated_pod}
                                || "$data->{author}/$data->{release}/$data->{path}";
                        }
                        $val = URI->new_abs( $val, $base )->as_string;
                    }
                    else {
                        $val = '/static/images/gray.png';
                    }
                }
                $tag .= qq{ $attr="} . escape_html($val) . qq{"};
            }
            $tag .= ' />';
            return $tag;
        },
    );
    $hr->process($html);
}

1;
