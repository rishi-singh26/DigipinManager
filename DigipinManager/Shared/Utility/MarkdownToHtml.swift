//
//  MarkdownToHtml.swift
//  DigipinManager
//
//  Created by Rishi Singh on 06/08/25.
//

import Foundation

class MarkdownToHtml {
    /// Converts Markdown text to HTML
    /// - Parameter markdown: The Markdown text to convert
    /// - Returns: HTML string
    static func convertToHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var htmlLines: [String] = []
        var i = 0
        var inCodeBlock = false
        var codeBlockLanguage = ""
        var inList = false
        var listType: ListType = .unordered
        var listLevel = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Handle code blocks
            if trimmedLine.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    htmlLines.append("</code></pre>")
                    inCodeBlock = false
                    codeBlockLanguage = ""
                } else {
                    // Start code block
                    let language = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeBlockLanguage = language.isEmpty ? "" : " class=\"language-\(language)\""
                    htmlLines.append("<pre><code\(codeBlockLanguage)>")
                    inCodeBlock = true
                }
                i += 1
                continue
            }
            
            // If inside code block, just add the line as-is (escaped)
            if inCodeBlock {
                htmlLines.append(escapeHTML(line))
                i += 1
                continue
            }
            
            // Handle empty lines
            if trimmedLine.isEmpty {
                if inList {
                    htmlLines.append(closeList(listType))
                    inList = false
                    listLevel = 0
                }
                htmlLines.append("")
                i += 1
                continue
            }
            
            // Handle headers
            if let headerResult = parseHeader(line) {
                if inList {
                    htmlLines.append(closeList(listType))
                    inList = false
                    listLevel = 0
                }
                htmlLines.append(headerResult)
                i += 1
                continue
            }
            
            // Handle horizontal rules
            if isHorizontalRule(trimmedLine) {
                if inList {
                    htmlLines.append(closeList(listType))
                    inList = false
                    listLevel = 0
                }
                htmlLines.append("<hr>")
                i += 1
                continue
            }
            
            // Handle blockquotes
            if trimmedLine.hasPrefix(">") {
                if inList {
                    htmlLines.append(closeList(listType))
                    inList = false
                    listLevel = 0
                }
                let (blockquoteHTML, linesProcessed) = parseBlockquote(lines, startIndex: i)
                htmlLines.append(blockquoteHTML)
                i += linesProcessed
                continue
            }
            
            // Handle lists
            if let listResult = parseListItem(line) {
                let currentListType = listResult.type
                let currentLevel = listResult.level
                
                if !inList {
                    htmlLines.append(openList(currentListType))
                    inList = true
                    listType = currentListType
                    listLevel = currentLevel
                } else if listType != currentListType || listLevel != currentLevel {
                    htmlLines.append(closeList(listType))
                    htmlLines.append(openList(currentListType))
                    listType = currentListType
                    listLevel = currentLevel
                }
                
                htmlLines.append("<li>\(processInlineMarkdown(listResult.content))</li>")
                i += 1
                continue
            }
            
            // Close list if we're in one but current line isn't a list item
            if inList {
                htmlLines.append(closeList(listType))
                inList = false
                listLevel = 0
            }
            
            // Handle regular paragraphs
            let (paragraphHTML, linesProcessed) = parseParagraph(lines, startIndex: i)
            htmlLines.append(paragraphHTML)
            i += linesProcessed
        }
        
        // Close any remaining open list
        if inList {
            htmlLines.append(closeList(listType))
        }
        
        return htmlLines.joined(separator: "\n")
    }
    
    static func getStyledHTML(_ html: String) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
                    line-height: 1.6;
                    color: #1d1d1f;
                    max-width: 100%;
                    margin: 0;
                    padding: 16px;
                    background-color: transparent;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                
                hr {
                    border: none;
                    border-top: 2px solid #e1e4e8;
                    margin: 24px 0;
                }
                
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #f5f5f7;
                    }
                    a {
                        color: #0984ff;
                    }
                    code {
                        background-color: #1c1c1e;
                        color: #ff6b35;
                    }
                    pre {
                        background-color: #1c1c1e;
                        border: 1px solid #3a3a3c;
                    }
                    h1, h2, h3, h4, h5, h6 {
                        color: #f5f5f7;
                    }
                    hr {
                        border-top-color: #3a3a3c;
                    }
                }
                
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 12px;
                    font-weight: 600;
                    line-height: 1.3;
                }
                
                h1 { 
                    font-size: 1.8em;
                    padding-bottom: 8px;
                }
                h2 { 
                    font-size: 1.5em;
                    padding-bottom: 6px;
                }
                h3 { font-size: 1.3em; }
                h4 { font-size: 1.1em; }
                
                p {
                    margin-bottom: 12px;
                }
                
                code {
                    background-color: #f6f6f6;
                    border-radius: 4px;
                    font-size: 0.85em;
                    padding: 2px 6px;
                    font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
                    color: #d73a49;
                    border: 1px solid #e1e4e8;
                }
                
                pre {
                    background-color: #f8f8f8;
                    border-radius: 8px;
                    font-size: 0.85em;
                    line-height: 1.4;
                    overflow-x: auto;
                    padding: 16px;
                    margin: 16px 0;
                    border: 1px solid #e1e4e8;
                }
                
                pre code {
                    background-color: transparent;
                    border: none;
                    color: #24292e;
                    padding: 0;
                }
                
                ul, ol {
                    padding-left: 20px;
                    margin-bottom: 12px;
                }
                
                li {
                    margin-bottom: 6px;
                    line-height: 1.5;
                }
                
                a {
                    color: #007aff;
                    text-decoration: none;
                }
                
                a:hover {
                    text-decoration: underline;
                }
                
                blockquote {
                    border-left: 4px solid #007aff;
                    margin: 16px 0;
                    padding: 0 16px;
                    color: #6d6d70;
                    font-style: italic;
                }
                
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                }
                
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin: 16px 0;
                }
                
                th, td {
                    border: 1px solid #e1e4e8;
                    padding: 8px 12px;
                    text-align: left;
                }
                
                th {
                    background-color: #f6f8fa;
                    font-weight: 600;
                }
            </style>
        </head>
        <body>
            <p>\(html)</p>
        </body>
        </html>
        """
    }
    
    /// Converts Markdown to styled HTML asynchronously.
    /// - Parameter markdown: The markdown string to convert.
    /// - Returns: The styled HTML string.
    static func convertMarkdownAsync(_ markdown: String) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let html = convertToHTML(markdown)
                let styledHtml = getStyledHTML(html)
                
                continuation.resume(returning: styledHtml)
            }
        }
    }
}


// MARK: - Private methods
extension MarkdownToHtml {
    // MARK: - Header Parsing
    static private func parseHeader(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // ATX headers (# Header)
        if trimmed.hasPrefix("#") {
            let headerMatch = trimmed.range(of: "^(#{1,6})\\s+(.+)$", options: .regularExpression)
            if let range = headerMatch {
                let headerText = String(trimmed[range])
                let components = headerText.components(separatedBy: " ")
                let level = components[0].count
                let title = components.dropFirst().joined(separator: " ")
                let processedTitle = processInlineMarkdown(title)
                return "<h\(level)>\(processedTitle)</h\(level)>"
            }
        }
        
        return nil
    }
    
    // MARK: - List Parsing
    private enum ListType {
        case ordered
        case unordered
    }
    
    private struct ListItem {
        let type: ListType
        let level: Int
        let content: String
    }
    
    static private func parseListItem(_ line: String) -> ListItem? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Unordered list patterns: -, *, +
        if let range = trimmed.range(of: "^[-*+]\\s+(.+)$", options: .regularExpression) {
            let content = String(trimmed[range]).dropFirst(2)
            return ListItem(type: .unordered, level: 1, content: String(content))
        }
        
        // Ordered list pattern: 1. Item
        if let range = trimmed.range(of: "^\\d+\\.\\s+(.+)$", options: .regularExpression) {
            let fullMatch = String(trimmed[range])
            if let dotIndex = fullMatch.firstIndex(of: ".") {
                let content = String(fullMatch[fullMatch.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
                return ListItem(type: .ordered, level: 1, content: content)
            }
        }
        
        return nil
    }
    
    static private func openList(_ type: ListType) -> String {
        return type == .ordered ? "<ol>" : "<ul>"
    }
    
    static private func closeList(_ type: ListType) -> String {
        return type == .ordered ? "</ol>" : "</ul>"
    }
    
    // MARK: - Blockquote Parsing
    static private func parseBlockquote(_ lines: [String], startIndex: Int) -> (html: String, linesProcessed: Int) {
        var blockquoteLines: [String] = []
        var i = startIndex
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix(">") {
                let content = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                blockquoteLines.append(content.isEmpty ? "" : content)
            } else if trimmed.isEmpty && i < lines.count - 1 && lines[i + 1].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                blockquoteLines.append("")
            } else {
                break
            }
            i += 1
        }
        
        let blockquoteContent = blockquoteLines.joined(separator: "\n")
        let processedContent = convertToHTML(blockquoteContent)
        let html = "<blockquote>\n\(processedContent)\n</blockquote>"
        
        return (html, i - startIndex)
    }
    
    // MARK: - Paragraph Parsing
    static private func parseParagraph(_ lines: [String], startIndex: Int) -> (html: String, linesProcessed: Int) {
        var paragraphLines: [String] = []
        var i = startIndex
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Stop at empty line, header, list, blockquote, or horizontal rule
            if trimmed.isEmpty ||
               parseHeader(line) != nil ||
               parseListItem(line) != nil ||
               trimmed.hasPrefix(">") ||
               isHorizontalRule(trimmed) ||
               trimmed.hasPrefix("```") {
                break
            }
            
            paragraphLines.append(line)
            i += 1
        }
        
        if paragraphLines.isEmpty {
            return ("", 1)
        }
        
        let paragraphContent = paragraphLines.joined(separator: " ")
        let processedContent = processInlineMarkdown(paragraphContent)
        let html = "<p>\(processedContent)</p>"
        
        return (html, i - startIndex)
    }
    
    // MARK: - Horizontal Rule Parsing
    static private func isHorizontalRule(_ line: String) -> Bool {
        let patterns = ["---", "***", "___"]
        for pattern in patterns {
            if line.replacingOccurrences(of: " ", with: "").hasPrefix(pattern) &&
               line.replacingOccurrences(of: " ", with: "").count >= 3 {
                return true
            }
        }
        return false
    }
    
    // MARK: - Inline Markdown Processing
    static private func processInlineMarkdown(_ text: String) -> String {
        var result = text
        
        // Process in order of precedence to avoid conflicts
        result = processInlineCode(result)
        result = processImages(result)
        result = processLinks(result)
        result = processBold(result)
        result = processItalic(result)
        result = processStrikethrough(result)
        
        return result
    }
    
    static private func processInlineCode(_ text: String) -> String {
        // Handle backtick code spans
        let pattern = "`([^`]+)`"
        return text.replacingOccurrences(
            of: pattern,
            with: "<code>$1</code>",
            options: .regularExpression
        )
    }
    
    static private func processBold(_ text: String) -> String {
        // Handle **bold** and __bold__
        var result = text
        result = result.replacingOccurrences(
            of: "\\*\\*([^*]+)\\*\\*",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "__([^_]+)__",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        return result
    }
    
    static private func processItalic(_ text: String) -> String {
        // Handle *italic* and _italic_
        var result = text
        result = result.replacingOccurrences(
            of: "(?<!\\*)\\*([^*]+)\\*(?!\\*)",
            with: "<em>$1</em>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "(?<!_)_([^_]+)_(?!_)",
            with: "<em>$1</em>",
            options: .regularExpression
        )
        return result
    }
    
    static private func processStrikethrough(_ text: String) -> String {
        // Handle ~~strikethrough~~
        return text.replacingOccurrences(
            of: "~~([^~]+)~~",
            with: "<del>$1</del>",
            options: .regularExpression
        )
    }
    
    static private func processLinks(_ text: String) -> String {
        // Handle [text](url) and [text](url "title")
        let pattern = "\\[([^\\]]+)\\]\\(([^\\)\\s]+)(?:\\s+\"([^\"]+)\")?\\)"
        return text.replacingOccurrences(of: pattern, with: { match in
            let nsString = text as NSString
            let matchRange = match.range
            let fullMatch = nsString.substring(with: matchRange)
            
            // Parse the components
            if let _ = fullMatch.range(of: pattern, options: .regularExpression) {
                let linkText = fullMatch.replacingOccurrences(
                    of: pattern,
                    with: "$1",
                    options: .regularExpression
                )
                let url = fullMatch.replacingOccurrences(
                    of: pattern,
                    with: "$2",
                    options: .regularExpression
                )
                let title = fullMatch.replacingOccurrences(
                    of: pattern,
                    with: "$3",
                    options: .regularExpression
                )
                
                let titleAttr = title.isEmpty ? "" : " title=\"\(self.escapeHTML(title))\""
                return "<a href=\"\(self.escapeHTML(url))\"\(titleAttr)>\(linkText)</a>"
            }
            
            return fullMatch
        }, options: .regularExpression)
    }
    
    static private func processImages(_ text: String) -> String {
        // Handle ![alt](src) and ![alt](src "title")
        let pattern = "!\\[([^\\]]*)\\]\\(([^\\)\\s]+)(?:\\s+\"([^\"]+)\")?\\)"
        return text.replacingOccurrences(of: pattern, with: { match in
            let nsString = text as NSString
            let matchRange = match.range
            let fullMatch = nsString.substring(with: matchRange)
            
            // Parse the components
            if let _ = fullMatch.range(of: pattern, options: .regularExpression) {
                let altText = fullMatch.replacingOccurrences(
                    of: pattern,
                    with: "$1",
                    options: .regularExpression
                )
                let src = fullMatch.replacingOccurrences(
                    of: pattern,
                    with: "$2",
                    options: .regularExpression
                )
                let title = fullMatch.replacingOccurrences(
                    of: pattern,
                    with: "$3",
                    options: .regularExpression
                )
                
                let titleAttr = title.isEmpty ? "" : " title=\"\(self.escapeHTML(title))\""
                return "<img src=\"\(self.escapeHTML(src))\" alt=\"\(self.escapeHTML(altText))\"\(titleAttr)>"
            }
            
            return fullMatch
        }, options: .regularExpression)
    }
    
    // MARK: - Utility Functions
    
    static private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }
}

extension String {
    func replacingOccurrences(of pattern: String, with replacement: @escaping (NSTextCheckingResult) -> String, options: NSString.CompareOptions) -> String {
        guard options.contains(.regularExpression) else {
            return self.replacingOccurrences(of: pattern, with: replacement(NSTextCheckingResult()))
        }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: self.count)
            let matches = regex.matches(in: self, options: [], range: range)
            
            var result = self
            var offset = 0
            
            for match in matches {
                let matchRange = NSRange(location: match.range.location + offset, length: match.range.length)
                let nsString = result as NSString
                // let matchString = nsString.substring(with: NSRange(location: match.range.location, length: match.range.length))
                let replacementString = replacement(match)
                
                result = nsString.replacingCharacters(in: matchRange, with: replacementString)
                offset += replacementString.count - match.range.length
            }
            
            return result
        } catch {
            return self
        }
    }
}
