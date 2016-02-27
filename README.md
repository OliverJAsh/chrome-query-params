# Query params Chrome extension

Chrome extension for editing URL query parameters.

https://chrome.google.com/webstore/detail/query-params/jgacgeahnbmkhdhldifidddbkneahmal

Written using [Elm](http://elm-lang.org/).

![Demo](demo.gif)

## Testing

```
./build.sh
```

Add the folder as a Chrome extension.

For testing outside of the Chrome extension infrastructure, run `elm-reactor`
and go to `popup.html`. You will need to update the input to use test data.

## Release

```
./build.sh
./bundle.sh
# manually upload artifact
```
