const getTab = () => new Promise((resolve, reject) => {
    chrome.tabs.query({ currentWindow: true, active: true }, tabs => resolve(tabs[0]));
});

const getTabUrl = () => getTab().then(tab => new URL(tab.url));
// For testing:
// const getTabUrl = () => Promise.resolve(window.location);

getTabUrl().then(url => {
    // Only works without ports
    // var main = Elm.fullscreenDebug('Main', 'Main.elm');
    // https://github.com/elm-lang/elm-reactor/issues/36
    // TODO: Send input as signal to show loading?
    const main = Elm.fullscreen(Elm.Main, { inputQueryParamsStr: url.search
        .replace(/^\?/, '') });

    main.ports.outputQueryParamsStr.subscribe(queryParamsStr => {
        getTabUrl().then(latestUrl => {
            // Warning: mutation!
            latestUrl.search = `?${queryParamsStr}`;
            chrome.tabs.update({ url: latestUrl.href });
        });
    });

    main.ports.focus.subscribe(focus => {
        if (focus) {
            // TODO: Why 50? rAF and 1 don't work
            setTimeout(() => {
                const nodes = document.querySelectorAll('tbody tr');
                const node = nodes[focus[0]];
                node.querySelector(`.${focus[1]}`).focus();
            }, 50);
        }
    });
});
