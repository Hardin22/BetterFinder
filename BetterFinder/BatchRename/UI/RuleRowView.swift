import SwiftUI

// MARK: - RuleRowView

struct RuleRowView: View {

    @Binding var activeRule: ActiveRule
    var onDelete: () -> Void
    var onChange:  () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Drag handle (visual; List provides the actual drag)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .frame(width: 14)
                .padding(.top, 6)

            // Inline editor — isolated sub-views carry their own @State
            editorView
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(activeRule.isEnabled ? 1 : 0.45)

            // Enable / disable
            Button {
                activeRule.isEnabled.toggle()
                onChange()
            } label: {
                Image(systemName: activeRule.isEnabled ? "eye" : "eye.slash")
                    .font(.system(size: 12))
                    .foregroundStyle(activeRule.isEnabled ? .secondary : .quaternary)
            }
            .buttonStyle(.plain)

            // Delete — wired to onDelete so the parent can remove the row
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.red.opacity(0.75))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(.background.opacity(0.6)))
    }

    // Route to the correct editor sub-view
    @ViewBuilder private var editorView: some View {
        switch activeRule.rule {
        case let .replace(f, r, cs, re):
            ReplaceEditor(activeRule: $activeRule, onChange: onChange,
                          initialFind: f, initialReplacement: r,
                          initialCaseSensitive: cs, initialRegex: re)

        case let .insert(text, pos):
            InsertEditor(activeRule: $activeRule, onChange: onChange,
                         initialText: text, initialPosition: pos)

        case let .removeRange(from, to):
            RemoveRangeEditor(activeRule: $activeRule, onChange: onChange,
                              initialFrom: from, initialTo: to)

        case let .removeCharacters(preset):
            RemoveCharactersEditor(activeRule: $activeRule, onChange: onChange, initialPreset: preset)

        case let .changeCase(style):
            ChangeCaseEditor(activeRule: $activeRule, onChange: onChange, initialStyle: style)

        case let .addNumber(pos, start, step, pad, sep):
            AddNumberEditor(activeRule: $activeRule, onChange: onChange,
                            initialPosition: pos, initialStart: start,
                            initialStep: step, initialPad: pad, initialSep: sep)

        case let .sequentialName(base, start, step, pad, sep):
            SequentialNameEditor(activeRule: $activeRule, onChange: onChange,
                                 initialBaseName: base, initialStart: start,
                                 initialStep: step, initialPad: pad, initialSep: sep)

        case let .insertDate(src, fmt, pos, sep):
            InsertDateEditor(activeRule: $activeRule, onChange: onChange,
                             initialSource: src, initialFormat: fmt,
                             initialPosition: pos, initialSep: sep)

        case let .insertMetadata(tags, sep, pos):
            InsertMetadataEditor(activeRule: $activeRule, onChange: onChange,
                                 initialTags: tags, initialSep: sep, initialPosition: pos)

        case let .changeExtension(ext):
            ChangeExtensionEditor(activeRule: $activeRule, onChange: onChange, initialExt: ext)

        case let .truncate(max, side):
            TruncateEditor(activeRule: $activeRule, onChange: onChange,
                           initialMax: max, initialSide: side)
        }
    }
}

// MARK: - Shared helpers

private func rowLabel(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
}

private func positionLabel(_ p: InsertPosition) -> String {
    switch p {
    case .prefix:  return "Prefix"
    case .suffix:  return "Suffix"
    case .atIndex: return "At Index"
    }
}

private func insertPositionFrom(_ label: String, current: InsertPosition) -> InsertPosition {
    switch label {
    case "Prefix": return .prefix
    case "Suffix": return .suffix
    default:
        if case let .atIndex(i) = current { return .atIndex(i) }
        return .atIndex(0)
    }
}

// MARK: - Replace

/// Uses local @State so the replacement TextField keeps its text during re-renders.
private struct ReplaceEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void

    @State private var find: String
    @State private var replacement: String
    @State private var isCaseSensitive: Bool
    @State private var isRegex: Bool

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialFind: String, initialReplacement: String,
         initialCaseSensitive: Bool, initialRegex: Bool) {
        _activeRule = activeRule
        self.onChange = onChange
        _find = State(initialValue: initialFind)
        _replacement = State(initialValue: initialReplacement)
        _isCaseSensitive = State(initialValue: initialCaseSensitive)
        _isRegex = State(initialValue: initialRegex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("Replace Text")
            HStack(spacing: 6) {
                TextField("Find", text: $find)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onChange(of: find) { _, _ in commit() }

                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                TextField("Replace", text: $replacement)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onChange(of: replacement) { _, _ in commit() }
            }
            HStack(spacing: 12) {
                Toggle("Case Sensitive", isOn: $isCaseSensitive)
                    .onChange(of: isCaseSensitive) { _, _ in commit() }
                Toggle("Regex", isOn: $isRegex)
                    .onChange(of: isRegex) { _, _ in commit() }
            }
            .toggleStyle(.checkbox)
            .font(.system(size: 11))
        }
    }

    private func commit() {
        activeRule.rule = .replace(find: find, replacement: replacement,
                                   isCaseSensitive: isCaseSensitive, isRegex: isRegex)
        onChange()
    }
}

// MARK: - Insert

private struct InsertEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void

    @State private var text: String
    @State private var position: InsertPosition

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialText: String, initialPosition: InsertPosition) {
        _activeRule = activeRule
        self.onChange = onChange
        _text = State(initialValue: initialText)
        _position = State(initialValue: initialPosition)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("Insert Text")
            HStack {
                TextField("Text to insert", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onChange(of: text) { _, _ in commit() }

                Picker("", selection: Binding(
                    get: { positionLabel(position) },
                    set: { position = insertPositionFrom($0, current: position); commit() }
                )) {
                    Text("Prefix").tag("Prefix")
                    Text("Suffix").tag("Suffix")
                    Text("At Index").tag("At Index")
                }
                .labelsHidden()
                .frame(width: 85)
            }
            if case let .atIndex(idx) = position {
                HStack {
                    Text("Index:").font(.system(size: 11)).foregroundStyle(.secondary)
                    Stepper(value: Binding(
                        get: { idx },
                        set: { position = .atIndex($0); commit() }
                    ), in: Int.min...Int.max) {
                        Text("\(idx)").font(.system(size: 11))
                    }
                    Text("(negative = from end)").font(.system(size: 10)).foregroundStyle(.quaternary)
                }
            }
        }
    }

    private func commit() {
        activeRule.rule = .insert(text: text, position: position)
        onChange()
    }
}

// MARK: - Remove Range

private struct RemoveRangeEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void

    @State private var from: Int
    @State private var to: Int

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialFrom: Int, initialTo: Int) {
        _activeRule = activeRule
        self.onChange = onChange
        _from = State(initialValue: initialFrom)
        _to   = State(initialValue: initialTo)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("Remove Range")
            HStack(spacing: 8) {
                Text("From").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField("", value: $from, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 55)
                    .onChange(of: from) { _, _ in commit() }

                Text("To").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField("", value: $to, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 55)
                    .onChange(of: to) { _, _ in commit() }

                Text("(negative = from end)").font(.system(size: 10)).foregroundStyle(.quaternary)
            }
        }
    }

    private func commit() {
        activeRule.rule = .removeRange(from: from, to: to)
        onChange()
    }
}

// MARK: - Remove Characters

private struct RemoveCharactersEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void

    @State private var preset: CharacterSetPreset
    @State private var customChars: String

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialPreset: CharacterSetPreset) {
        _activeRule = activeRule
        self.onChange = onChange
        _preset = State(initialValue: initialPreset)
        if case let .custom(c) = initialPreset {
            _customChars = State(initialValue: c)
        } else {
            _customChars = State(initialValue: "")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("Remove Characters")
            HStack {
                Picker("", selection: Binding(
                    get: { presetLabel(preset) },
                    set: { preset = presetFrom($0); commit() }
                )) {
                    Text("Whitespace").tag("Whitespace")
                    Text("Special Chars").tag("Special Chars")
                    Text("Digits").tag("Digits")
                    Text("Custom").tag("Custom")
                }
                .labelsHidden()
                .frame(width: 120)

                if case .custom = preset {
                    TextField("chars to remove", text: $customChars)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onChange(of: customChars) { _, _ in
                            preset = .custom(customChars)
                            commit()
                        }
                }
            }
        }
    }

    private func presetLabel(_ p: CharacterSetPreset) -> String {
        switch p {
        case .whitespace: return "Whitespace"
        case .specialChars: return "Special Chars"
        case .digits: return "Digits"
        case .custom: return "Custom"
        }
    }

    private func presetFrom(_ label: String) -> CharacterSetPreset {
        switch label {
        case "Special Chars": return .specialChars
        case "Digits": return .digits
        case "Custom": return .custom(customChars)
        default: return .whitespace
        }
    }

    private func commit() {
        activeRule.rule = .removeCharacters(preset: preset)
        onChange()
    }
}

// MARK: - Change Case

private struct ChangeCaseEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void
    @State private var style: CaseStyle

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void, initialStyle: CaseStyle) {
        _activeRule = activeRule; self.onChange = onChange
        _style = State(initialValue: initialStyle)
    }

    var body: some View {
        HStack {
            rowLabel("Change Case")
            Picker("", selection: $style) {
                ForEach(CaseStyle.allCases, id: \.self) { s in
                    Text(s.rawValue.capitalized).tag(s)
                }
            }
            .labelsHidden()
            .frame(width: 120)
            .onChange(of: style) { _, _ in
                activeRule.rule = .changeCase(style: style)
                onChange()
            }
        }
    }
}

// MARK: - Add Number

private struct AddNumberEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void

    @State private var position: InsertPosition
    @State private var startAt: Int
    @State private var step: Int
    @State private var padToDigits: Int
    @State private var separator: String

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialPosition: InsertPosition, initialStart: Int, initialStep: Int,
         initialPad: Int, initialSep: String) {
        _activeRule = activeRule; self.onChange = onChange
        _position    = State(initialValue: initialPosition)
        _startAt     = State(initialValue: initialStart)
        _step        = State(initialValue: initialStep)
        _padToDigits = State(initialValue: initialPad)
        _separator   = State(initialValue: initialSep)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("Add Number")
            HStack(spacing: 8) {
                Picker("", selection: Binding(
                    get: { positionLabel(position) },
                    set: { position = insertPositionFrom($0, current: position); commit() }
                )) {
                    Text("Prefix").tag("Prefix")
                    Text("Suffix").tag("Suffix")
                    Text("At Index").tag("At Index")
                }
                .labelsHidden().frame(width: 85)

                Text("Start").font(.system(size: 11)).foregroundStyle(.secondary)
                Stepper(value: $startAt, in: 0...Int.max) { Text("\(startAt)").font(.system(size: 11)) }
                    .onChange(of: startAt) { _, _ in commit() }

                Text("Step").font(.system(size: 11)).foregroundStyle(.secondary)
                Stepper(value: $step, in: 1...100) { Text("\(step)").font(.system(size: 11)) }
                    .onChange(of: step) { _, _ in commit() }
            }
            HStack(spacing: 8) {
                Text("Pad").font(.system(size: 11)).foregroundStyle(.secondary)
                Stepper(value: $padToDigits, in: 0...8) { Text("\(padToDigits)").font(.system(size: 11)) }
                    .onChange(of: padToDigits) { _, _ in commit() }

                Text("Sep").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField("", text: $separator)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 50)
                    .onChange(of: separator) { _, _ in commit() }
            }
        }
    }

    private func commit() {
        activeRule.rule = .addNumber(position: position, startAt: startAt, step: step,
                                      padToDigits: padToDigits, separator: separator)
        onChange()
    }
}

// MARK: - Insert Date

private struct InsertDateEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void

    @State private var source: DateSource
    @State private var format: String
    @State private var position: InsertPosition
    @State private var separator: String

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialSource: DateSource, initialFormat: String,
         initialPosition: InsertPosition, initialSep: String) {
        _activeRule = activeRule; self.onChange = onChange
        _source    = State(initialValue: initialSource)
        _format    = State(initialValue: initialFormat)
        _position  = State(initialValue: initialPosition)
        _separator = State(initialValue: initialSep)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("Insert Date")
            HStack(spacing: 8) {
                Picker("", selection: $source) {
                    Text("Creation").tag(DateSource.creationDate)
                    Text("Modified").tag(DateSource.modificationDate)
                    Text("Today").tag(DateSource.currentDate)
                }
                .labelsHidden().frame(width: 90)
                .onChange(of: source) { _, _ in commit() }

                TextField("yyyy-MM-dd", text: $format)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 130)
                    .onChange(of: format) { _, _ in commit() }

                Picker("", selection: Binding(
                    get: { positionLabel(position) },
                    set: { position = insertPositionFrom($0, current: position); commit() }
                )) {
                    Text("Prefix").tag("Prefix")
                    Text("Suffix").tag("Suffix")
                    Text("At Index").tag("At Index")
                }
                .labelsHidden().frame(width: 85)

                TextField("_", text: $separator)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 40)
                    .help("Separator between date and name")
                    .onChange(of: separator) { _, _ in commit() }
            }
        }
    }

    private func commit() {
        activeRule.rule = .insertDate(source: source, format: format,
                                       position: position, separator: separator)
        onChange()
    }
}

// MARK: - Insert Metadata

private struct InsertMetadataEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void

    @State private var tags: [MetadataTag]
    @State private var separator: String
    @State private var position: InsertPosition

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialTags: [MetadataTag], initialSep: String, initialPosition: InsertPosition) {
        _activeRule = activeRule; self.onChange = onChange
        _tags      = State(initialValue: initialTags)
        _separator = State(initialValue: initialSep)
        _position  = State(initialValue: initialPosition)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("Insert Metadata")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(MetadataTag.allCases, id: \.self) { tag in
                        Toggle(tag.rawValue, isOn: Binding(
                            get: { tags.contains(tag) },
                            set: { on in
                                if on { tags.append(tag) } else { tags.removeAll { $0 == tag } }
                                commit()
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .font(.system(size: 10))
                    }
                }
                .padding(.vertical, 2)
            }
            HStack(spacing: 8) {
                TextField("_", text: $separator)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 50)
                    .help("Separator between tags")
                    .onChange(of: separator) { _, _ in commit() }

                Picker("", selection: Binding(
                    get: { positionLabel(position) },
                    set: { position = insertPositionFrom($0, current: position); commit() }
                )) {
                    Text("Prefix").tag("Prefix")
                    Text("Suffix").tag("Suffix")
                    Text("At Index").tag("At Index")
                }
                .labelsHidden().frame(width: 85)
            }
        }
    }

    private func commit() {
        activeRule.rule = .insertMetadata(tags: tags, separator: separator, position: position)
        onChange()
    }
}

// MARK: - Change Extension

private struct ChangeExtensionEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void
    @State private var ext: String

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void, initialExt: String) {
        _activeRule = activeRule; self.onChange = onChange
        _ext = State(initialValue: initialExt)
    }

    var body: some View {
        HStack {
            rowLabel("Change Extension")
            TextField("e.g. jpg", text: $ext)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 90)
                .onChange(of: ext) { _, _ in
                    activeRule.rule = .changeExtension(newExtension: ext)
                    onChange()
                }
        }
    }
}

// MARK: - Truncate

private struct TruncateEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void
    @State private var maxLength: Int
    @State private var side: TruncateSide

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialMax: Int, initialSide: TruncateSide) {
        _activeRule = activeRule; self.onChange = onChange
        _maxLength = State(initialValue: initialMax)
        _side      = State(initialValue: initialSide)
    }

    var body: some View {
        HStack(spacing: 8) {
            rowLabel("Truncate")
            Text("Max").font(.system(size: 11)).foregroundStyle(.secondary)
            Stepper(value: $maxLength, in: 1...Int.max) {
                Text("\(maxLength)").font(.system(size: 11))
            }
            .onChange(of: maxLength) { _, _ in commit() }

            Text("from").font(.system(size: 11)).foregroundStyle(.secondary)
            Picker("", selection: $side) {
                Text("Start").tag(TruncateSide.start)
                Text("End").tag(TruncateSide.end)
            }
            .labelsHidden().frame(width: 70)
            .onChange(of: side) { _, _ in commit() }
        }
    }

    private func commit() {
        activeRule.rule = .truncate(maxLength: maxLength, from: side)
        onChange()
    }
}

// MARK: - Sequential Name

private struct SequentialNameEditor: View {
    @Binding var activeRule: ActiveRule
    var onChange: () -> Void

    @State private var baseName: String
    @State private var startAt: Int
    @State private var step: Int
    @State private var padToDigits: Int
    @State private var separator: String

    init(activeRule: Binding<ActiveRule>, onChange: @escaping () -> Void,
         initialBaseName: String, initialStart: Int, initialStep: Int,
         initialPad: Int, initialSep: String) {
        _activeRule = activeRule; self.onChange = onChange
        _baseName    = State(initialValue: initialBaseName)
        _startAt     = State(initialValue: initialStart)
        _step        = State(initialValue: initialStep)
        _padToDigits = State(initialValue: initialPad)
        _separator   = State(initialValue: initialSep)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("Sequential Name")
            HStack(spacing: 6) {
                Text("Name").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField("e.g. Week", text: $baseName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onChange(of: baseName) { _, _ in commit() }

                Text("Sep").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField(" ", text: $separator)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 40)
                    .onChange(of: separator) { _, _ in commit() }
            }
            HStack(spacing: 8) {
                Text("Start").font(.system(size: 11)).foregroundStyle(.secondary)
                Stepper(value: $startAt, in: 0...Int.max) {
                    Text("\(startAt)").font(.system(size: 11))
                }
                .onChange(of: startAt) { _, _ in commit() }

                Text("Step").font(.system(size: 11)).foregroundStyle(.secondary)
                Stepper(value: $step, in: 1...100) {
                    Text("\(step)").font(.system(size: 11))
                }
                .onChange(of: step) { _, _ in commit() }

                Text("Pad").font(.system(size: 11)).foregroundStyle(.secondary)
                Stepper(value: $padToDigits, in: 0...8) {
                    Text("\(padToDigits)").font(.system(size: 11))
                }
                .onChange(of: padToDigits) { _, _ in commit() }
            }
            // Preview hint
            Text("Preview: \(previewHint)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.quaternary)
        }
    }

    private var previewHint: String {
        let num1 = startAt
        let num2 = startAt + step
        let fmt: (Int) -> String = { n in
            padToDigits > 0 ? String(format: "%0\(padToDigits)d", n) : "\(n)"
        }
        let name = baseName.isEmpty ? "Name" : baseName
        return "\(name)\(separator)\(fmt(num1)), \(name)\(separator)\(fmt(num2)), \u{2026}"
    }

    private func commit() {
        activeRule.rule = .sequentialName(baseName: baseName, startAt: startAt, step: step,
                                           padToDigits: padToDigits, separator: separator)
        onChange()
    }
}
