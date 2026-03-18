import Foundation

// MARK: - Bookkeeping Entry

struct BookkeepingEntry: Identifiable {
    let id: String
    let description: String
    let amount: Double
    let category: BookkeepingCategory
    let isIncome: Bool
    let date: Date
    let navId: String

    /// Format: 💰 描述 | ¥金额 | 分类 | 支出/收入
    static let separator = " | "
    static let prefix = "💰 "

    var formattedContent: String {
        let type = isIncome ? "收入" : "支出"
        let amountStr = String(format: "%.2f", amount)
        return "\(Self.prefix)\(description)\(Self.separator)¥\(amountStr)\(Self.separator)\(category.rawValue)\(Self.separator)\(type)"
    }

    static func parse(from nav: NavInfo) -> BookkeepingEntry? {
        let content = nav.content
        guard content.hasPrefix(prefix) else { return nil }

        let stripped = String(content.dropFirst(prefix.count))
        let parts = stripped.components(separatedBy: separator)
        guard parts.count >= 3 else { return nil }

        let desc = parts[0].trimmingCharacters(in: .whitespaces)
        let amountStr = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "¥", with: "")
        guard let amount = Double(amountStr) else { return nil }

        let categoryStr = parts[2].trimmingCharacters(in: .whitespaces)
        let category = BookkeepingCategory(rawValue: categoryStr) ?? .other

        let isIncome = parts.count > 3 && parts[3].trimmingCharacters(in: .whitespaces) == "收入"

        let date: Date
        if let createdAt = nav.createdAt {
            date = ISO8601DateFormatter().date(from: createdAt) ?? Date()
        } else {
            date = Date()
        }

        return BookkeepingEntry(
            id: nav.id,
            description: desc,
            amount: amount,
            category: category,
            isIncome: isIncome,
            date: date,
            navId: nav.id
        )
    }
}

// MARK: - Category

enum BookkeepingCategory: String, CaseIterable {
    case food = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case entertainment = "娱乐"
    case housing = "住房"
    case medical = "医疗"
    case education = "教育"
    case salary = "工资"
    case investment = "投资"
    case other = "其他"

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .housing: return "house.fill"
        case .medical: return "cross.case.fill"
        case .education: return "book.fill"
        case .salary: return "briefcase.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle.fill"
        }
    }

    /// Keywords for auto-detection from voice input
    static func detect(from text: String) -> BookkeepingCategory {
        let t = text.lowercased()
        let foodKeys = ["饭", "餐", "吃", "喝", "咖啡", "奶茶", "外卖", "食", "菜", "面", "粥", "早", "午", "晚", "宵夜", "火锅", "烧烤", "小吃", "水果", "零食", "饮料"]
        let transportKeys = ["车", "打车", "地铁", "公交", "出租", "滴滴", "油", "加油", "停车", "高铁", "机票", "飞机", "火车"]
        let shoppingKeys = ["买", "购", "淘宝", "京东", "衣服", "鞋", "包", "化妆", "日用", "超市"]
        let entertainmentKeys = ["电影", "游戏", "KTV", "旅游", "玩", "票", "演出", "健身", "运动"]
        let housingKeys = ["房租", "水电", "物业", "房贷", "装修", "家具", "电费", "水费", "燃气"]
        let medicalKeys = ["医", "药", "看病", "体检", "保险"]
        let educationKeys = ["学", "课", "书", "培训", "考试"]
        let salaryKeys = ["工资", "薪", "奖金", "提成"]
        let investmentKeys = ["股", "基金", "理财", "利息", "分红"]

        if foodKeys.contains(where: { t.contains($0) }) { return .food }
        if transportKeys.contains(where: { t.contains($0) }) { return .transport }
        if shoppingKeys.contains(where: { t.contains($0) }) { return .shopping }
        if entertainmentKeys.contains(where: { t.contains($0) }) { return .entertainment }
        if housingKeys.contains(where: { t.contains($0) }) { return .housing }
        if medicalKeys.contains(where: { t.contains($0) }) { return .medical }
        if educationKeys.contains(where: { t.contains($0) }) { return .education }
        if salaryKeys.contains(where: { t.contains($0) }) { return .salary }
        if investmentKeys.contains(where: { t.contains($0) }) { return .investment }
        return .other
    }
}

// MARK: - Amount Parsing

enum AmountParser {
    /// Extract amount from natural language text like "午饭花了35块" or "打车50元"
    static func parse(from text: String) -> Double? {
        // Try patterns: number followed by 块/元/¥/$, or 花了/花/付了/付 + number
        let patterns = [
            #"(\d+\.?\d*)\s*[块元]"#,
            #"[¥￥$]\s*(\d+\.?\d*)"#,
            #"花了?\s*(\d+\.?\d*)"#,
            #"付了?\s*(\d+\.?\d*)"#,
            #"(\d+\.?\d*)\s*[块元钱]"#,
            #"收入?\s*(\d+\.?\d*)"#,
            #"(\d+\.?\d*)"#  // fallback: any number
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                let numStr = String(text[range])
                if let amount = Double(numStr), amount > 0 {
                    return amount
                }
            }
        }
        return nil
    }

    /// Check if text describes income
    static func isIncome(from text: String) -> Bool {
        let incomeKeys = ["收入", "工资", "奖金", "提成", "利息", "分红", "报销", "退款", "收到", "进账"]
        return incomeKeys.contains(where: { text.contains($0) })
    }

    /// Extract description (remove amount-related words)
    static func extractDescription(from text: String) -> String {
        var desc = text
        // Remove amount patterns
        let removePatterns = [
            #"\d+\.?\d*\s*[块元钱]"#,
            #"[¥￥$]\s*\d+\.?\d*"#,
            #"花了?\s*\d+\.?\d*"#,
            #"付了?\s*\d+\.?\d*"#,
        ]
        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                desc = regex.stringByReplacingMatches(in: desc, range: NSRange(desc.startIndex..., in: desc), withTemplate: "")
            }
        }
        desc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        return desc.isEmpty ? text : desc
    }
}

// MARK: - Stats Period

enum StatsPeriod: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case year = "本年"
}
