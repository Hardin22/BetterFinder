import SwiftUI

/// Compact filter bar that appears below the path bar whenever a search query is active.
/// Shows scope selector, match-mode menu, and file-kind menu.
struct SearchFilterBar: View {
    @Bindable var browser: BrowserState
    @Environment(AppState.self) private var appState

    private var defaultOptions: SearchOptions { appState.preferences.defaultSearchOptions }
    private var isNonDefault: Bool { browser.searchOptions != defaultOptions }

    var body: some View {
        HStack(spacing: 0) {

            // ── Scope buttons ───────────────────────────────────────────────
            HStack(spacing: 2) {
                ForEach(SearchOptions.SearchScope.allCases) { scope in
                    scopeButton(scope)
                }
            }
            .padding(.leading, 8)

            separator()

            // ── Match mode ──────────────────────────────────────────────────
            optionMenu(
                icon:  "text.magnifyingglass",
                label: browser.searchOptions.matchMode.shortLabel
            ) {
                ForEach(SearchOptions.MatchMode.allCases) { mode in
                    Button {
                        browser.searchOptions.matchMode = mode
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                            if browser.searchOptions.matchMode == mode {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            separator()

            // ── File kind ───────────────────────────────────────────────────
            optionMenu(
                icon:  browser.searchOptions.fileKind.icon,
                label: browser.searchOptions.fileKind == .any
                    ? "Any Kind" : browser.searchOptions.fileKind.rawValue
            ) {
                ForEach(SearchOptions.FileKindFilter.allCases) { kind in
                    Button {
                        browser.searchOptions.fileKind = kind
                    } label: {
                        Label(kind.rawValue, systemImage: kind.icon)
                    }
                }
            }

            Spacer()

            // ── Status / spinner ────────────────────────────────────────────
            if browser.isSearching {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 4)
                Text("Searching…")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
            } else if browser.searchOptions.scope.isAsync {
                let count = browser.searchResults.count
                if count > 0 {
                    Text("\(count) result\(count == 1 ? "" : "s")")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                }
            }

            // ── Reset ───────────────────────────────────────────────────────
            if isNonDefault {
                Button {
                    browser.searchOptions = defaultOptions
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Reset search options to defaults")
                .padding(.trailing, 8)
            }
        }
        .frame(height: 27)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Scope button

    private func scopeButton(_ scope: SearchOptions.SearchScope) -> some View {
        let selected = browser.searchOptions.scope == scope
        return Button {
            browser.searchOptions.scope = scope
        } label: {
            HStack(spacing: 3) {
                Image(systemName: scope.icon)
                    .font(.system(size: 10))
                Text(scope.rawValue)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(selected ? Color.accentColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(selected ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(selected ? Color.accentColor : Color.primary)
        .animation(.easeInOut(duration: 0.12), value: selected)
    }

    // MARK: - Option menu button

    private func optionMenu<Content: View>(
        icon: String,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .padding(.horizontal, 2)
    }

    // MARK: - Separator

    private func separator() -> some View {
        Divider()
            .frame(height: 14)
            .padding(.horizontal, 6)
    }
}
