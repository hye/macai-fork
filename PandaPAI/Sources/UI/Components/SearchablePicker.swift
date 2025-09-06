import SwiftUI

struct SearchablePicker<SelectionValue: Hashable, Label: View>: View {
    let options: [SelectionValue]
    @Binding var selection: SelectionValue
    let label: Label
    let onChange: (SelectionValue) -> Void
    let displayName: (SelectionValue) -> String

    @State private var searchText = ""
    @State private var isExpanded = false

    init(
        options: [SelectionValue],
        selection: Binding<SelectionValue>,
        onChange: @escaping (SelectionValue) -> Void,
        displayName: @escaping (SelectionValue) -> String = { "\($0)" },
        @ViewBuilder label: () -> Label
    ) {
        self.options = options
        self._selection = selection
        self.onChange = onChange
        self.displayName = displayName
        self.label = label()
    }

    // 过滤后的选项
    private var filteredOptions: [SelectionValue] {
        if searchText.isEmpty {
            return options
        } else {
            return options.filter { option in
                displayName(option).localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 选择器按钮
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(displayName(selection))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .cornerRadius(8)
            }

            // 内联搜索和选项列表
            if isExpanded {
                VStack(spacing: 0) {
                    // 搜索框
                    TextField("搜索选项...", text: $searchText)                        .textInputAutocapitalization(.none)
                      .autocorrectionDisabled()

                        .padding(10)
                        .border(width: 3, edges: [.bottom], color: .accentColor)
                        .foregroundStyle(LinearGradient(colors: [.gray,.white], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    // 选项列表
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredOptions, id: \.self) { option in
                                HStack {
                                    Text(displayName(option))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal)
                                    if selection == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selection = option
                                    onChange(option)
                                    isExpanded = false
                                    searchText = ""
                                }
                                .background(selection == option ? Color.accentColor.opacity(0.1) : Color.clear)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .cornerRadius(8)
                .padding(.top, 4)
            }
        }
    }
}

// 使用示例
/*
SearchablePicker(
    options: types,
    selection: $viewModel.type,
    onChange: { newValue in
        viewModel.onChangeApiType(newValue)
    },
    displayName: { type in
        AppConstants.defaultApiConfigurations[type]?.name ?? type
    }
) {
    Text("選擇類型")
}
*/
    
