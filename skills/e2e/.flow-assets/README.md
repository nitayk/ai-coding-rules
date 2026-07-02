# flow.html build assets

- `svg-pan-zoom-3.6.1.min.js` — vendored [svg-pan-zoom](https://github.com/ariutta/svg-pan-zoom) v3.6.1 (MIT). Inlined into `flow.html` by `scripts/build-flow-html.py`. Network-free, reproducible builds.

Regenerate the viewer after editing `flow.d2`:
```sh
cd skills/e2e && d2 flow.d2 flow.svg && python3 ../../scripts/build-flow-html.py
```
