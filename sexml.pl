#!/usr/bin/env perl

# A very simplistic Pegex parser for sexml

use Pegex;

my $grammar = <<'...';
sexml: block*
block: - '{' tag + attr* % + - ( block | text )+ - '}' -
tag: ident
attr: / ':' ident (: '{' text '}' )? /
ident: / ( WORD+ ) /
text: /- ( [^\{\}]+ ) /
...

my $input = <<'...';
{body :lang{fr} :editable
    {div :class{abstract important}
    {p s-expr is way more readable and
    editable than xml and more saner than a builder based on nested
    datastructures because}
        {ul
            {li i can compile and collapse the structure as the
            longest string as possible}
            {li this dialect is even more readable than the
            equivalent perl6 datastructure}
            {li parentheses are at the right place: it is soooo easy
            to edit it with a decent editor (vi for example) }
            {li this is {a :href{http://acmeism.org/} acmeic}, i
            really think it's important for a template system}
        }
    }
}
...

{
    package SexML::Object;
    use Pegex::Base;
    extends 'Pegex::Tree';

    sub got_text {
        my ($self, $got) = @_;
        $got =~ s/\s+/ /g;
        return $got;
    }

    sub got_block {
        my ($self, $got) = @_;
        my ($tag, $attr, $body) = @$got;
        return {
            $tag => {
                @$attr ? (
                    attr => { map { $_->[0], $_->[1] || 1 } @$attr }
                ) : (),
                body => $body
            }
        }
    }
}

{
    package SexML::XML;
    use Pegex::Base;
    extends 'SexML::Object';

    sub final {
        my ($self, $got) = @_;
        my $xml = $self->render($got->[0]);
    }

    sub render {
        my ($self, $object) = @_;
        return $object unless ref $object;
        my ($tag) = keys %$object;
        my $attr = $self->attr($object->{$tag}{attr});
        my $body = join '', map $self->render($_),
            @{$object->{$tag}{body}};
        $body =~ s/^</\n</;
        return "<$tag$attr>$body</$tag>\n"
    }

    sub attr {
        my ($self, $hash) = @_;
        return '' unless $hash;
        ' ' . (join ' ', map qq[$_="$hash->{$_}"], sort keys %$hash);
    }
}

use XXX;
XXX pegex($grammar)->parse($input);
# XXX pegex($grammar, 'SexML::Object')->parse($input);
# XXX pegex($grammar, 'SexML::XML')->parse($input);
