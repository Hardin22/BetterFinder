/browser.terminalChangeDirectory?(targetURL)/a\
    }\
\
    @objc private func openInExternalTerminal() {\
        let targetURL: URL\
        if let idx = tableView.selectedRowIndexes.first,\
           idx < items.count,\
           !items[idx].isDirectory {\
            targetURL = items[idx].url.deletingLastPathComponent()\
        } else if let idx = tableView.selectedRowIndexes.first,\
                  idx < items.count {\
            targetURL = items[idx].url\
        } else {\
            targetURL = browser.currentURL\
        }\
        appState.preferences.externalTerminal.open(url: targetURL)\

