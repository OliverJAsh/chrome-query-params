import React, { FC, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";

const Popup: FC<{ initialUrl: URL }> = ({ initialUrl }) => {
  const [url, setUrl] = useState<URL>(() => initialUrl);
  const params = url.searchParams;
  const setParams = (params: URLSearchParams) => {
    const copy = new URL(url);
    copy.search = params.toString();
    setUrl(copy);
  };

  console.log("params", [...params]);

  useEffect(() => {
    console.log("write", url);
    const id = setTimeout(() => {
      chrome.tabs.update({ url: url.href });
    }, 3000);
    return () => {
      clearTimeout(id);
    };
  }, [url]);

  const add = () => {
    setParams(new URLSearchParams([...params, ["", ""]]));
  };

  const update = (
    index: number,
    fn: (x: [string, string]) => [string, string]
  ) => {
    setParams(
      new URLSearchParams([...params].map((x, i) => (i === index ? fn(x) : x)))
    );
  };

  const ddelete = (index: number) => {
    setParams(new URLSearchParams([...params].filter((_, i) => i !== index)));
  };

  return (
    <>
      <table>
        <thead>
          <tr>
            <th>Key</th>
            <th>Value</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {[...params].map(([key, value], index) => (
            // TODO: use a proper ID to avoid issues
            <tr key={index}>
              <td>
                <input
                  value={key}
                  onChange={(e) =>
                    update(index, ([, v]) => [e.target.value, v])
                  }
                />
              </td>
              <td>
                <input
                  value={value}
                  onChange={(e) => update(index, ([k]) => [k, e.target.value])}
                />
              </td>
              <td>
                <button onClick={() => ddelete(index)}>Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <button onClick={add}>Add param</button>
    </>
  );
};

const getTab = () =>
  new Promise<chrome.tabs.Tab>((resolve) => {
    chrome.tabs.query({ currentWindow: true, active: true }, (tabs) =>
      resolve(tabs[0])
    );
  });

getTab().then((tab) => {
  const root = createRoot(document.getElementById("root")!);
  root.render(<Popup initialUrl={new URL(tab.url!)} />);
});
