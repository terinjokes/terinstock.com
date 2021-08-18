+++
date = "2021-08-18T09:20:00Z"
title = "Clearing Custom Search Engines in Chrome"
description = "A snippet to remove Custom Search Engines from Google's Chrome"
+++

In addition to your search engine in Google Chrome, the browser tries to be
helpful by remembering [custom search engines][OpenSearch] for websites you
visit in the course of navigating the web. As some websites can become
registered simply by navigating to their homepage, this can result in a very
long list of custom search engines.

[OpenSearch]: https://developer.mozilla.org/en-US/docs/Web/OpenSearch#autodiscovery_of_search_plugins

Unfortunately, the page to manage custom search engines in Google Chrome
(currently located at `chrome://settings/searchEngines`) leaves a lot to be
desired. This page has no mechanism for bulk editing. With over two hundred
engines registered, I did not want to click my mouse to manually manage them.

Fortunately, we can activate super developer powers!

```javascript
const nl = document.querySelector("settings-ui").shadowRoot
  .querySelector("#main").shadowRoot
  .querySelector("[role=main]").shadowRoot
  .querySelector("settings-search-page").shadowRoot
  .querySelector("settings-search-engines-page").shadowRoot
  .querySelector("#otherEngines").shadowRoot
  .querySelectorAll("settings-search-engine-entry");
```

Ah, right. So, the settings pages uses [Shadow DOM][Shadow DOM], which makes
getting to the actual list of custom search engines a bit of a chore. Query
through a bunch of document fragments to get to the actual list.

[Shadow DOM]: https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_shadow_DOM

```javascript
const ops = Array.from(nl).map((elem) => elem.shadowRoot)
  .filter((elem) => {
    return !elem.querySelector("#keyword-column").innerText.startsWith("!");
  })
  .map((elem) => {
    return [elem.querySelector("#keyword-column").innerText, elem.querySelector("#delete")];
  });

console.table(ops);
```

I use the custom search engine feature to implement DuckDuckGo-style [!Bang
searches][bang]. So before removing engines, I filter out items starting with
"!".

[bang]: https://duckduckgo.com/bang

If the table printed to the console looks good, click the virtual mouse.

```javascript
ops.forEach(entry => entry[1].click());
```
