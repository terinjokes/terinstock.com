+++
date = "2014-02-27T00:00:00Z"
title = "Replacing packages in a Browserify bundle"
aliases = [
  "/blog/2014/02/27/replacing-packages-in-a-browserify-bundle.html"
]
+++

As a developer on a large Backbone application built with [Browserify](https://github.com/substack/node-browserify), there are a number of occasions where I want to replace one dependency with another. In this specific case, I wanted to swap `underscore` for `lodash`.

Browserify already supports this with the "browser field" in `package.json`.

> There is a special "browser" field you can set in your package.json on a per-module basis to override file resolution for browser-specific versions of files.

This only works for resolution within your package, if any of your dependency packages require Underscore they'll get Underscore. This is to help ensure your replacements don't break your dependencies.

However, it's suboptimal to ship both Lo-Dash and Underscore, as is maintaining a fork simply to replace the dependency. In these edge cases, it's useful to replace files or packages even within dependencies.

Luckily, the Browserify transform [browserify-swap](https://github.com/thlorenz/browserify-swap) allows you swap dependencies in certain packages, as defined via the `@packages` key, while generating the output bundle.

As I want to replace Underscore in Backbone, Marionnette and related packages, the configuration seemed pretty straight-forward.

```json
/* package.json */
{
  "browserify": {
    "transform": [
      "browserify-swap"
    ]
  },
  "browserify-swap": {
    "@packages": [
      "backbone",
      "marionette",
      "backbone.babysitter",
      "backbone.wreqr"
    ],
    "all": {
      "underscore.js$": "lodash"
    }
  }
}
```

I was a bit discouraged to find that Underscore was still present in the output bundle. After triple-checking that my configuration was valid, I broke out the node debugger to find what was wrong.

I believed `browserify-swap` to swap files while resolving the require calls. The transform actually checks if the current file path [matches a RegEx](https://github.com/thlorenz/browserify-swap/blob/fbb9ca86c8af14e3fa21a75852f6251ea86f45d7/index.js#L38) defined in the `package.json` file and replaces the contents to require the swapped in file.

## The Solution

With this information in hand, it became clear that we needed to swap in the `underscore` package.

```json
/* package.json */
{
  "browserify": {
    "transform": [
      "browserify-swap"
    ]
  },
  "browserify-swap": {
    "@packages": [
      "underscore"
    ],
    "all": {
      "underscore.js$": "lodash"
    }
  }
}
```

This causes the swap to happen for each instance of Underscore in the bundle, but only the one instance of Lo-Dash would be included.

I believe that the transform should also allow swapping packages for other packages, as the folder structure of a package is usually not part of the public API. I've [opened an issue](https://github.com/thlorenz/browserify-swap/issues/1) against the project.
