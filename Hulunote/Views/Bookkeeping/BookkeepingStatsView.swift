import SwiftUI

struct BookkeepingStatsView: View {
    @Bindable var viewModel: BookkeepingViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.hulunoteBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Period picker
                    Picker("周期", selection: $viewModel.statsPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    ScrollView {
                        VStack(spacing: 16) {
                            // Overview cards
                            overviewCards

                            // Category breakdown
                            if !viewModel.categoryBreakdown.isEmpty {
                                categorySection
                            }

                            // Entry list
                            if !viewModel.filteredEntries.isEmpty {
                                entryListSection
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("账单统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        viewModel.showStats = false
                    }
                    .foregroundColor(.hulunoteAccent)
                }
            }
        }
    }

    // MARK: - Overview Cards

    @ViewBuilder
    private var overviewCards: some View {
        HStack(spacing: 12) {
            // Expense
            VStack(spacing: 6) {
                Text("总支出")
                    .font(.caption)
                    .foregroundColor(.hulunoteTextSecondary)
                Text("¥\(String(format: "%.2f", viewModel.totalExpense))")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.hulunoteCard)
            .cornerRadius(12)

            // Income
            VStack(spacing: 6) {
                Text("总收入")
                    .font(.caption)
                    .foregroundColor(.hulunoteTextSecondary)
                Text("¥\(String(format: "%.2f", viewModel.totalIncome))")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundColor(.hulunoteSuccess)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.hulunoteCard)
            .cornerRadius(12)

            // Balance
            VStack(spacing: 6) {
                Text("结余")
                    .font(.caption)
                    .foregroundColor(.hulunoteTextSecondary)
                let balance = viewModel.totalIncome - viewModel.totalExpense
                Text("\(balance >= 0 ? "+" : "")¥\(String(format: "%.2f", balance))")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundColor(balance >= 0 ? .hulunoteSuccess : .red)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.hulunoteCard)
            .cornerRadius(12)
        }
    }

    // MARK: - Category Breakdown

    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("支出分类")
                .font(.body.bold())
                .foregroundColor(.hulunoteTextPrimary)

            ForEach(viewModel.categoryBreakdown, id: \.category) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.hulunoteAccent)
                        .frame(width: 28)

                    Text(item.category.rawValue)
                        .font(.body)
                        .foregroundColor(.hulunoteTextPrimary)

                    Spacer()

                    // Percentage bar
                    let pct = viewModel.totalExpense > 0
                        ? item.amount / viewModel.totalExpense
                        : 0

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.hulunotePurpleStart, .hulunotePurpleEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * pct)
                    }
                    .frame(width: 80, height: 6)

                    Text("¥\(String(format: "%.0f", item.amount))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.hulunoteTextSecondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color.hulunoteCard)
        .cornerRadius(12)
    }

    // MARK: - Entry List

    @ViewBuilder
    private var entryListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("明细 (\(viewModel.filteredEntries.count)笔)")
                .font(.body.bold())
                .foregroundColor(.hulunoteTextPrimary)

            ForEach(viewModel.filteredEntries) { entry in
                HStack(spacing: 10) {
                    Image(systemName: entry.category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.hulunoteTextSecondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.description)
                            .font(.body)
                            .foregroundColor(.hulunoteTextPrimary)
                            .lineLimit(1)

                        let formatter = DateFormatter()
                        Text({
                            let f = DateFormatter()
                            f.dateFormat = "MM-dd"
                            return f.string(from: entry.date)
                        }())
                        .font(.caption)
                        .foregroundColor(.hulunoteTextMuted)
                    }

                    Spacer()

                    Text("\(entry.isIncome ? "+" : "-")¥\(String(format: "%.2f", entry.amount))")
                        .font(.body.monospacedDigit())
                        .foregroundColor(entry.isIncome ? .hulunoteSuccess : .orange)
                }
                .padding(.vertical, 3)

                if entry.id != viewModel.filteredEntries.last?.id {
                    Divider()
                        .background(Color.hulunoteBorder)
                }
            }
        }
        .padding(14)
        .background(Color.hulunoteCard)
        .cornerRadius(12)
    }
}
