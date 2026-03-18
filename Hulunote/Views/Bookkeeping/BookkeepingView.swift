import SwiftUI

struct BookkeepingView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let databaseId: String
    @State private var viewModel: BookkeepingViewModel?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color.hulunoteBackground.ignoresSafeArea()

            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Today summary card
                    todaySummary(vm: vm)

                    // Entries list
                    entriesList(vm: vm)

                    // Recording bar
                    if vm.speechService.isRecording {
                        recordingBar(vm: vm)
                    }

                    // Input bar
                    inputBar(vm: vm)
                }
                .sheet(isPresented: Binding(
                    get: { vm.showConfirmSheet },
                    set: { vm.showConfirmSheet = $0 }
                )) {
                    confirmSheet(vm: vm)
                }
                .sheet(isPresented: Binding(
                    get: { vm.showStats },
                    set: { vm.showStats = $0 }
                )) {
                    BookkeepingStatsView(viewModel: vm)
                }
            }
        }
        .navigationTitle("记账")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel?.showStats = true
                    Task { await viewModel?.loadAllEntries() }
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.hulunoteAccent)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = BookkeepingViewModel(
                    databaseId: databaseId,
                    apiClient: appViewModel.apiClient
                )
            }
        }
        .task {
            await viewModel?.loadToday()
        }
    }

    // MARK: - Today Summary

    @ViewBuilder
    private func todaySummary(vm: BookkeepingViewModel) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日支出")
                    .font(.caption)
                    .foregroundColor(.hulunoteTextSecondary)
                Text("¥\(String(format: "%.2f", vm.todayExpense))")
                    .font(.title2.bold())
                    .foregroundColor(.orange)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("今日收入")
                    .font(.caption)
                    .foregroundColor(.hulunoteTextSecondary)
                Text("¥\(String(format: "%.2f", vm.todayIncome))")
                    .font(.title2.bold())
                    .foregroundColor(.hulunoteSuccess)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color.hulunotePurpleStart.opacity(0.3), Color.hulunotePurpleEnd.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Entries List

    @ViewBuilder
    private func entriesList(vm: BookkeepingViewModel) -> some View {
        ScrollView {
            if vm.isLoading && vm.entries.isEmpty {
                ProgressView()
                    .tint(.hulunoteAccent)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if vm.entries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "yensign.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.hulunoteTextSecondary)
                    Text("今日暂无记录")
                        .font(.body)
                        .foregroundColor(.hulunoteTextSecondary)
                    Text("语音或文字输入开始记账")
                        .font(.caption)
                        .foregroundColor(.hulunoteTextMuted)
                }
                .frame(maxWidth: .infinity, minHeight: 250)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(vm.entries) { entry in
                        entryRow(entry: entry, vm: vm)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Entry Row

    @ViewBuilder
    private func entryRow(entry: BookkeepingEntry, vm: BookkeepingViewModel) -> some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: entry.category.icon)
                .font(.system(size: 20))
                .foregroundColor(.hulunoteAccent)
                .frame(width: 36, height: 36)
                .background(Color.hulunoteAccent.opacity(0.15))
                .clipShape(Circle())

            // Description & category
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.description)
                    .font(.body)
                    .foregroundColor(.hulunoteTextPrimary)
                    .lineLimit(1)
                Text(entry.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.hulunoteTextMuted)
            }

            Spacer()

            // Amount
            Text("\(entry.isIncome ? "+" : "-")¥\(String(format: "%.2f", entry.amount))")
                .font(.body.monospacedDigit().bold())
                .foregroundColor(entry.isIncome ? .hulunoteSuccess : .orange)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.hulunoteCard)
        .cornerRadius(10)
        .contextMenu {
            Button(role: .destructive) {
                Task { await vm.deleteEntry(entry) }
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    // MARK: - Recording Bar

    @ViewBuilder
    private func recordingBar(vm: BookkeepingViewModel) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .modifier(PulseModifier())

            Text("\(vm.speechService.recordingTimeRemaining)s")
                .font(.caption)
                .foregroundColor(.red)
                .monospacedDigit()

            Text(vm.speechService.recognizedText.isEmpty
                 ? "说出消费内容..."
                 : vm.speechService.recognizedText)
                .font(.caption)
                .foregroundColor(.hulunoteTextSecondary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.hulunoteSidebar)
    }

    // MARK: - Input Bar

    @ViewBuilder
    private func inputBar(vm: BookkeepingViewModel) -> some View {
        HStack(spacing: 10) {
            // Mic button
            Button {
                vm.toggleRecording()
            } label: {
                Image(systemName: vm.speechService.isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 22))
                    .foregroundColor(vm.speechService.isRecording ? .red : .hulunoteTextSecondary)
            }

            TextField("午饭花了35块...", text: Binding(
                get: { vm.inputText },
                set: { vm.inputText = $0 }
            ), axis: .vertical)
            .lineLimit(1...3)
            .font(.body)
            .foregroundColor(.hulunoteTextPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.hulunoteInputBackground)
            .cornerRadius(20)
            .focused($isInputFocused)
            .onSubmit {
                vm.parseInput()
            }

            Button {
                vm.parseInput()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(
                        vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .hulunoteTextMuted
                            : .hulunoteAccent
                    )
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.hulunoteSidebar)
    }

    // MARK: - Confirm Sheet

    @ViewBuilder
    private func confirmSheet(vm: BookkeepingViewModel) -> some View {
        NavigationView {
            ZStack {
                Color.hulunoteBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Amount
                    VStack(spacing: 8) {
                        Text(vm.isIncome ? "收入" : "支出")
                            .font(.caption)
                            .foregroundColor(.hulunoteTextSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("¥")
                                .font(.title2)
                                .foregroundColor(.hulunoteTextSecondary)
                            TextField("0.00", value: Binding(
                                get: { vm.parsedAmount ?? 0 },
                                set: { vm.parsedAmount = $0 }
                            ), format: .number)
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(vm.isIncome ? .hulunoteSuccess : .orange)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("描述")
                            .font(.caption)
                            .foregroundColor(.hulunoteTextSecondary)
                        TextField("消费描述", text: Binding(
                            get: { vm.parsedDescription },
                            set: { vm.parsedDescription = $0 }
                        ))
                        .font(.body)
                        .foregroundColor(.hulunoteTextPrimary)
                        .padding(12)
                        .background(Color.hulunoteInputBackground)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)

                    // Income/Expense toggle
                    VStack(alignment: .leading, spacing: 6) {
                        Text("类型")
                            .font(.caption)
                            .foregroundColor(.hulunoteTextSecondary)
                        Picker("类型", selection: Binding(
                            get: { vm.isIncome },
                            set: { vm.isIncome = $0 }
                        )) {
                            Text("支出").tag(false)
                            Text("收入").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 20)

                    // Category grid
                    VStack(alignment: .leading, spacing: 6) {
                        Text("分类")
                            .font(.caption)
                            .foregroundColor(.hulunoteTextSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(BookkeepingCategory.allCases, id: \.self) { cat in
                                Button {
                                    vm.parsedCategory = cat
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 20))
                                        Text(cat.rawValue)
                                            .font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        vm.parsedCategory == cat
                                            ? Color.hulunoteAccent.opacity(0.3)
                                            : Color.hulunoteCard
                                    )
                                    .foregroundColor(
                                        vm.parsedCategory == cat
                                            ? .hulunoteAccent
                                            : .hulunoteTextSecondary
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Save button
                    Button {
                        Task { await vm.saveEntry() }
                    } label: {
                        Text("保存")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.hulunotePurpleStart, .hulunotePurpleEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("确认记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        vm.showConfirmSheet = false
                    }
                    .foregroundColor(.hulunoteAccent)
                }
            }
        }
        .presentationDetents([.large])
    }
}
