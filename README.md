# Query params Chrome extension

Chrome extension which provides a user interface to read/write URL query parameters for the currently active tab.. Written using [Elm](http://elm-lang.org/).

https://chrome.google.com/webstore/detail/query-params/jgacgeahnbmkhdhldifidddbkneahmal

![Demo](demo.gif)

## Installation

```bash
yarn global add elm@0.16
```

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
