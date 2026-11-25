import UIKit
import SwiftUI

/// Draws simple pages of headings, text and tables into a PDF (US Letter).
///
/// Everything is real text, not pictures, so an AI assistant (or a person) can read every number.
final class ReportPDFWriter {

    enum Block {
        case title(String, subtitle: String)
        case heading(String)
        case paragraph(String)
        case note(String)
        /// Highlighted text, e.g. the ready-made question for an AI assistant.
        case box(String)
        case table(Table)
    }

    struct Table {
        /// Column titles. Empty for a simple two-column list with no header row.
        var headers: [String]
        /// Relative column widths.
        var widths: [CGFloat]
        var rows: [[String]]
        /// Columns aligned right (numbers).
        var rightAligned: Set<Int> = []
    }

    private let page = CGRect(x: 0, y: 0, width: 612, height: 792)
    private let margin: CGFloat = 48
    private let footer: String

    private var context: UIGraphicsPDFRendererContext?
    private var y: CGFloat = 0
    private var pageNumber = 0

    private let blue = UIColor(Theme.blue)
    private let secondary = UIColor(white: 0.4, alpha: 1)

    init(footer: String) {
        self.footer = footer
    }

    private var contentWidth: CGFloat { page.width - margin * 2 }
    /// Lowest point content can reach (the footer sits below it).
    private var bottom: CGFloat { page.height - margin - 16 }

    func write(_ blocks: [Block], title: String, to url: URL) throws {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: title,
            kCGPDFContextCreator as String: "FitForge",
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: page, format: format)
        try renderer.writePDF(to: url) { context in
            self.context = context
            self.newPage()
            for block in blocks {
                self.draw(block)
            }
        }
    }

    // MARK: - Blocks

    private func draw(_ block: Block) {
        switch block {
        case .title(let title, let subtitle):
            drawText(attributed(title, font: .boldSystemFont(ofSize: 22)), after: 4)
            drawText(attributed(subtitle, font: .systemFont(ofSize: 10), color: secondary), after: 14)

        case .heading(let text):
            let heading = attributed(text, font: .boldSystemFont(ofSize: 14), color: blue)
            // Keep a heading with at least a few lines of what follows it.
            ensureSpace(height(of: heading, width: contentWidth) + 60)
            y += 8
            drawText(heading, after: 6)

        case .paragraph(let text):
            drawText(attributed(text, font: .systemFont(ofSize: 10)), after: 8)

        case .note(let text):
            drawText(attributed(text, font: .systemFont(ofSize: 8.5), color: secondary), after: 8)

        case .box(let text):
            let content = attributed(text, font: .systemFont(ofSize: 10))
            let padding: CGFloat = 10
            let textHeight = height(of: content, width: contentWidth - padding * 2)
            ensureSpace(textHeight + padding * 2)
            let rect = CGRect(x: margin, y: y, width: contentWidth, height: textHeight + padding * 2)
            blue.withAlphaComponent(0.08).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 8).fill()
            content.draw(
                with: rect.insetBy(dx: padding, dy: padding),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            y += rect.height + 12

        case .table(let table):
            drawTable(table)
        }
    }

    private func drawTable(_ table: Table) {
        let total = max(table.widths.reduce(0, +), 1)
        let widths = table.widths.map { $0 / total * contentWidth }
        let font = UIFont.systemFont(ofSize: 9)
        let bold = UIFont.boldSystemFont(ofSize: 9)
        let headerBackground = UIColor(white: 0.93, alpha: 1)

        func rowHeight(_ cells: [String], font: UIFont) -> CGFloat {
            let heights = zip(cells, widths).map { cell, width in
                height(of: attributed(cell, font: font), width: width - 8)
            }
            return (heights.max() ?? 10) + 6
        }

        func drawRow(_ cells: [String], font: UIFont, background: UIColor?) {
            let rowHeight = rowHeight(cells, font: font)
            if let background {
                background.setFill()
                UIRectFill(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight))
            }
            var x = margin
            for (index, cell) in cells.enumerated() where index < widths.count {
                let alignment: NSTextAlignment = table.rightAligned.contains(index) ? .right : .left
                attributed(cell, font: font, alignment: alignment).draw(
                    with: CGRect(x: x + 4, y: y + 3, width: widths[index] - 8, height: rowHeight - 6),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
                x += widths[index]
            }
            y += rowHeight
            UIColor(white: 0.85, alpha: 1).setFill()
            UIRectFill(CGRect(x: margin, y: y - 0.5, width: contentWidth, height: 0.5))
        }

        let hasHeader = !table.headers.isEmpty

        // Header plus the first row together, so a header is never stranded at the bottom of a page.
        let headerHeight = hasHeader ? rowHeight(table.headers, font: bold) : 0
        ensureSpace(headerHeight + rowHeight(table.rows.first ?? [], font: font))
        if hasHeader {
            drawRow(table.headers, font: bold, background: headerBackground)
        }

        for row in table.rows {
            if y + rowHeight(row, font: font) > bottom {
                newPage()
                if hasHeader {
                    drawRow(table.headers, font: bold, background: headerBackground)
                }
            }
            drawRow(row, font: font, background: nil)
        }
        y += 12
    }

    // MARK: - Pages and text

    private func newPage() {
        context?.beginPage()
        pageNumber += 1
        y = margin
        attributed("\(footer) · Page \(pageNumber)", font: .systemFont(ofSize: 8), color: secondary)
            .draw(in: CGRect(x: margin, y: page.height - margin + 8, width: contentWidth, height: 14))
    }

    private func ensureSpace(_ needed: CGFloat) {
        if y + needed > bottom { newPage() }
    }

    private func drawText(_ text: NSAttributedString, after spacing: CGFloat) {
        let textHeight = height(of: text, width: contentWidth)
        ensureSpace(textHeight)
        text.draw(
            with: CGRect(x: margin, y: y, width: contentWidth, height: textHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        y += textHeight + spacing
    }

    private func attributed(_ text: String, font: UIFont, color: UIColor = .black,
                            alignment: NSTextAlignment = .left) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byWordWrapping
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style,
        ])
    }

    private func height(of text: NSAttributedString, width: CGFloat) -> CGFloat {
        ceil(text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height)
    }
}
