# NAME

Flexconf - Configuration files management library and program

Currently this module API and CLI is subject to change.

Any suggestions or bugreports are appreciated at issue tracker.
Show your support and acceptance of package and ideas by starring.
Please visit https://github.com/oklas/flexconf for that.

# SYNOPSIS

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

# DESCRIPTION

Flexconf is base for configuration management

# LICENSE

Copyright (C) Serguei Okladnikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Serguei Okladnikov <oklaspec@gmail.com>
