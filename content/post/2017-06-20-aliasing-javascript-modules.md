+++
date = "2017-06-20T17:45:55Z"
title = "Aliasing JavaScript Modules"
+++

A number of years ago I wrote a [blog post][replacing-packages] detailing how to replace modules in a
Browserify bundle. In the interceding years, the JavaScript ecosystem has had at
least three lifetimes, and we're now due for an update.

[replacing-packages]: {{< relref "2014-02-27-replacing-packages-in-a-browserify-bundle.md#the-solution" >}}

## Browserify

As the last post focused entirely on Browserify, I'll first revisit it first. As
noted in the previous post, the `browserify-swap` transform is designed to swap
individual files, not modules. We were able to work around it by defining the
configuration as a RegExp, but it's easy to get wrong. You can now use the
[aliasify][aliasify] transform, which does support replacing modules.

[aliasify]: https://github.com/benbria/aliasify

After installing, enable the transform, and add a new section to your
package.json.

```json
{
    "browserify": {
        "transform": [
            "aliasify"
        ]
    },
    "aliasify": {
        "aliases": {
            "underscore": "lodash"
        }
    }
}
```

In addition to aliasing modules, aliasify supports replacments that are relative
to the file calling require, as well as using RegExps to define replacement.

## Webpack

Webpack supports aliasing modules [right out of the box][webpack], no plugins needed. Just
add an additional section to your Webpack configuration.

[webpack]: https://webpack.js.org/configuration/resolve/#resolve-alias

```json
{
    "resolve": {
        "alias": {
            "underscore": "lodash"
        }
    }
}
```

## Babel

You can also setup aliases in Babel with the [`babel-plugin-module-resolver`][module-resolver] plugin. Like
the above, just add a section to your Babel configuration.

[module-resolver]: https://github.com/tleunen/babel-plugin-module-resolver

```json
{
    "plugins": [
        ["module-resolver", {
            "root": ["."],
            "alias": {
                "underscore": "lodash"
            }
        }]
    ]
}
```

## Yarn

Finally, you can alias before dependencies are even written to disk if you use
Yarn[^yarn]. Since it breaks compatibility with npm, it's best if you only use this
method in private applications, not public applications or in libraries.

[^yarn]: Unfortunately, it seems this isn't yet in the documentation. It has, however, been a "Yarn tip". {{< tweet 873958247304232961 >}}

In this method you combine the alias with defining your dependencies in
package.json.

```json
{
    "dependencies": {
        "underscore": "npm:lodash"
    }
}
```

Unlike the other methods in this guide, using the Yarn method also allows you to
install the same dependency at different versions by giving them different
names.

```json
{
    "dependencies": {
        "lodash3": "npm:lodash@^3",
        "lodash4": "npm:lodash@^4"
    }
}
```