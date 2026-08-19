// SKSoftwareLabelRenderer.swift
// OpenSpriteKit

import OpenFoundation

/// Deterministic bitmap text renderer used by the CGImage software path.
/// Browser presentation continues to use CATextLayer and Canvas2D for full font shaping.
internal enum SKSoftwareLabelRenderer {
    private static let glyphs: [Character: [UInt8]] = [
        " ": [0, 0, 0, 0, 0, 0, 0],
        "!": [4, 4, 4, 4, 4, 0, 4], "\"": [10, 10, 10, 0, 0, 0, 0],
        "#": [10, 31, 10, 10, 31, 10, 0], "$": [4, 15, 20, 14, 5, 30, 4],
        "%": [24, 25, 2, 4, 8, 19, 3], "&": [12, 18, 20, 8, 21, 18, 13],
        "'": [4, 4, 8, 0, 0, 0, 0], "(": [2, 4, 8, 8, 8, 4, 2],
        ")": [8, 4, 2, 2, 2, 4, 8], "*": [0, 4, 21, 14, 21, 4, 0],
        "+": [0, 4, 4, 31, 4, 4, 0], ",": [0, 0, 0, 0, 4, 4, 8],
        "-": [0, 0, 0, 31, 0, 0, 0], ".": [0, 0, 0, 0, 0, 0, 4],
        "/": [1, 2, 2, 4, 8, 8, 16], ":": [0, 4, 0, 0, 4, 0, 0],
        ";": [0, 4, 0, 0, 4, 4, 8], "<": [2, 4, 8, 16, 8, 4, 2],
        "=": [0, 0, 31, 0, 31, 0, 0], ">": [8, 4, 2, 1, 2, 4, 8],
        "?": [14, 17, 1, 2, 4, 0, 4], "@": [14, 17, 23, 21, 23, 16, 14],
        "0": [14, 17, 19, 21, 25, 17, 14], "1": [4, 12, 4, 4, 4, 4, 14],
        "2": [14, 17, 1, 2, 4, 8, 31], "3": [30, 1, 1, 14, 1, 1, 30],
        "4": [2, 6, 10, 18, 31, 2, 2], "5": [31, 16, 16, 30, 1, 1, 30],
        "6": [14, 16, 16, 30, 17, 17, 14], "7": [31, 1, 2, 4, 8, 8, 8],
        "8": [14, 17, 17, 14, 17, 17, 14], "9": [14, 17, 17, 15, 1, 1, 14],
        "A": [14, 17, 17, 31, 17, 17, 17], "B": [30, 17, 17, 30, 17, 17, 30],
        "C": [14, 17, 16, 16, 16, 17, 14], "D": [30, 17, 17, 17, 17, 17, 30],
        "E": [31, 16, 16, 30, 16, 16, 31], "F": [31, 16, 16, 30, 16, 16, 16],
        "G": [14, 17, 16, 23, 17, 17, 15], "H": [17, 17, 17, 31, 17, 17, 17],
        "I": [14, 4, 4, 4, 4, 4, 14], "J": [7, 2, 2, 2, 2, 18, 12],
        "K": [17, 18, 20, 24, 20, 18, 17], "L": [16, 16, 16, 16, 16, 16, 31],
        "M": [17, 27, 21, 21, 17, 17, 17], "N": [17, 25, 21, 19, 17, 17, 17],
        "O": [14, 17, 17, 17, 17, 17, 14], "P": [30, 17, 17, 30, 16, 16, 16],
        "Q": [14, 17, 17, 17, 21, 18, 13], "R": [30, 17, 17, 30, 20, 18, 17],
        "S": [15, 16, 16, 14, 1, 1, 30], "T": [31, 4, 4, 4, 4, 4, 4],
        "U": [17, 17, 17, 17, 17, 17, 14], "V": [17, 17, 17, 17, 17, 10, 4],
        "W": [17, 17, 17, 21, 21, 21, 10], "X": [17, 17, 10, 4, 10, 17, 17],
        "Y": [17, 17, 10, 4, 4, 4, 4], "Z": [31, 1, 2, 4, 8, 16, 31],
        "[": [14, 8, 8, 8, 8, 8, 14], "\\": [16, 8, 8, 4, 2, 2, 1],
        "]": [14, 2, 2, 2, 2, 2, 14], "^": [4, 10, 17, 0, 0, 0, 0],
        "_": [0, 0, 0, 0, 0, 0, 31], "`": [8, 4, 2, 0, 0, 0, 0],
        "{": [2, 4, 4, 8, 4, 4, 2], "|": [4, 4, 4, 4, 4, 4, 4],
        "}": [8, 4, 4, 2, 4, 4, 8], "~": [0, 0, 9, 22, 0, 0, 0],
        "…": [0, 0, 0, 0, 0, 0, 21]
    ]

    static func render(_ label: SKLabelNode, to context: CGContext) {
        guard let text = label.text, !text.isEmpty, label.fontSize > 0 else { return }

        let scale = max(label.fontSize / 7, 0.25)
        let advance = scale * 6
        let lineHeight = scale * 8
        let lines = layoutLines(for: label, text: text, advance: advance)
        guard !lines.isEmpty else { return }

        let baseBounds = label._contentBounds
        let color = blendedColor(for: label)
        context.saveGState()
        context.setFillColor(color.cgColor)

        for (lineIndex, line) in lines.enumerated() {
            let lineWidth = CGFloat(line.count) * advance
            let startX: CGFloat
            switch label.horizontalAlignmentMode {
            case .left: startX = baseBounds.minX
            case .center: startX = -lineWidth / 2
            case .right: startX = baseBounds.maxX - lineWidth
            }
            let baselineY = baseBounds.maxY - CGFloat(lineIndex + 1) * lineHeight + scale

            for (characterIndex, character) in line.enumerated() {
                let glyph = glyphRows(for: character)
                let originX = startX + CGFloat(characterIndex) * advance
                for row in 0..<7 {
                    let bits = glyph[row]
                    for column in 0..<5 where bits & (1 << (4 - column)) != 0 {
                        context.fill(CGRect(
                            x: originX + CGFloat(column) * scale,
                            y: baselineY + CGFloat(6 - row) * scale,
                            width: scale,
                            height: scale
                        ))
                    }
                }
            }
        }
        context.restoreGState()
    }

    private static func glyphRows(for character: Character) -> [UInt8] {
        if let glyph = glyphs[character] { return glyph }
        let uppercase = Character(String(character).uppercased())
        if let glyph = glyphs[uppercase] { return glyph }
        return [31, 17, 21, 21, 21, 17, 31]
    }

    private static func layoutLines(for label: SKLabelNode, text: String, advance: CGFloat) -> [String] {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard label.preferredMaxLayoutWidth > 0 else {
            return limited(lines, count: label.numberOfLines)
        }

        let capacity = max(1, Int(floor(label.preferredMaxLayoutWidth / advance)))
        switch label.lineBreakMode {
        case .byWordWrapping, .byCharWrapping:
            lines = lines.flatMap { line in
                wrapped(line, capacity: capacity, byWords: label.lineBreakMode == .byWordWrapping)
            }
        case .byClipping:
            lines = lines.map { String($0.prefix(capacity)) }
        case .byTruncatingHead:
            lines = lines.map { $0.count > capacity ? "…" + String($0.suffix(max(0, capacity - 1))) : $0 }
        case .byTruncatingTail:
            lines = lines.map { $0.count > capacity ? String($0.prefix(max(0, capacity - 1))) + "…" : $0 }
        case .byTruncatingMiddle:
            lines = lines.map { line in
                guard line.count > capacity else { return line }
                let remaining = max(0, capacity - 1)
                let head = (remaining + 1) / 2
                return String(line.prefix(head)) + "…" + String(line.suffix(remaining - head))
            }
        }
        return limited(lines, count: label.numberOfLines)
    }

    private static func wrapped(_ line: String, capacity: Int, byWords: Bool) -> [String] {
        guard line.count > capacity else { return [line] }
        if !byWords {
            var result: [String] = []
            var remainder = line[...]
            while !remainder.isEmpty {
                let end = remainder.index(remainder.startIndex, offsetBy: min(capacity, remainder.count))
                result.append(String(remainder[..<end]))
                remainder = remainder[end...]
            }
            return result
        }

        var result: [String] = []
        var current = ""
        for word in line.split(separator: " ", omittingEmptySubsequences: false).map(String.init) {
            let candidate = current.isEmpty ? word : current + " " + word
            if candidate.count <= capacity {
                current = candidate
            } else {
                if !current.isEmpty { result.append(current) }
                if word.count > capacity {
                    result.append(contentsOf: wrapped(word, capacity: capacity, byWords: false))
                    current = ""
                } else {
                    current = word
                }
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    private static func limited(_ lines: [String], count: Int) -> [String] {
        count > 0 ? Array(lines.prefix(count)) : lines
    }

    private static func blendedColor(for label: SKLabelNode) -> SKColor {
        let fontColor = label.fontColor ?? .white
        guard let blendColor = label.color, label.colorBlendFactor > 0 else { return fontColor }
        var fr: CGFloat = 0, fg: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        fontColor.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        blendColor.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let factor = min(max(label.colorBlendFactor, 0), 1)
        return SKColor(
            red: fr + (br - fr) * factor,
            green: fg + (bg - fg) * factor,
            blue: fb + (bb - fb) * factor,
            alpha: fa + (ba - fa) * factor
        )
    }
}
