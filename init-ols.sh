#!/bin/sh
# more about ols.json: https://github.com/DanielGavin/ols
(echo | cat << ```
{
  "collections": [
    { "name": "core", "path": "${HOME}/odin/core" },
    { "name": "vendor", "path": "${HOME}/odin/vendor" },
  ],
  "enable_semantic_tokens": false,
  "enable_document_symbols": true,
  "enable_hover": true,
  "enable_snippets": true,
  "verbose": true,
}
```
) > ols.json
