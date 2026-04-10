import SwiftUI
import WebKit

struct MarkdownPreviewView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        loadContent(into: webView)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    private func loadContent(into webView: WKWebView) {
        let url = self.url
        Task.detached(priority: .userInitiated) {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                let html = "<pre>Error loading file</pre>"
                _ = await MainActor.run {
                    webView.loadHTMLString(html, baseURL: nil)
                }
                return
            }
            let html = await Self.wrapInHTML(content)
            _ = await MainActor.run {
                webView.loadHTMLString(html, baseURL: nil)
            }
        }
    }
    
    private static func wrapInHTML(_ markdown: String) -> String {
        let escaped = markdown
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
            :root {
                --md-bg: #ffffff;
                --md-fg: #1e1e1e;
                --md-link: #0066cc;
                --md-code-bg: #f5f5f5;
                --md-code-border: #e0e0e0;
                --md-h1: #1a1a1a;
                --md-h2: #2a2a2a;
                --md-hr: #ddd;
                --md-blockquote-bg: #f8f8f8;
                --md-blockquote-border: #888;
            }
            @media (prefers-color-scheme: dark) {
                :root {
                    --md-bg: #1e1e1e;
                    --md-fg: #d4d4d4;
                    --md-link: #5da3f5;
                    --md-code-bg: #2d2d2d;
                    --md-code-border: #404040;
                    --md-h1: #e0e0e0;
                    --md-h2: #d0d0d0;
                    --md-hr: #404040;
                    --md-blockquote-bg: #252525;
                    --md-blockquote-border: #666;
                }
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                font-size: 13px;
                line-height: 1.6;
                color: var(--md-fg);
                background-color: var(--md-bg);
                padding: 16px;
                margin: 0;
            }
            a { color: var(--md-link); text-decoration: none; }
            a:hover { text-decoration: underline; }
            h1 { font-size: 24px; font-weight: 600; color: var(--md-h1); border-bottom: 1px solid var(--md-hr); padding-bottom: 8px; margin: 24px 0 16px; }
            h2 { font-size: 20px; font-weight: 600; color: var(--md-h2); border-bottom: 1px solid var(--md-hr); padding-bottom: 6px; margin: 24px 0 16px; }
            h3 { font-size: 16px; font-weight: 600; margin: 20px 0 12px; }
            p { margin: 0 0 16px; }
            ul, ol { margin: 0 0 16px; padding-left: 24px; }
            li { margin-bottom: 4px; }
            code { font-family: "SF Mono", Menlo, Monaco, monospace; font-size: 12px; background: var(--md-code-bg); padding: 2px 6px; border-radius: 4px; border: 1px solid var(--md-code-border); }
            pre { background: var(--md-code-bg); padding: 12px; border-radius: 6px; overflow-x: auto; margin: 0 0 16px; border: 1px solid var(--md-code-border); }
            pre code { background: none; padding: 0; border: none; }
            blockquote { margin: 0 0 16px; padding: 8px 16px; background: var(--md-blockquote-bg); border-left: 4px solid var(--md-blockquote-border); }
            hr { border: none; border-top: 1px solid var(--md-hr); margin: 24px 0; }
            table { width: 100%; border-collapse: collapse; margin: 0 0 16px; }
            th, td { border: 1px solid var(--md-code-border); padding: 8px 12px; text-align: left; }
            th { background: var(--md-blockquote-bg); font-weight: 600; }
            img { max-width: 100%; height: auto; border-radius: 4px; }
            </style>
        </head>
        <body>
        """
        
        // Simple markdown to HTML converter (handles common syntax)
        var converted = escaped
        
        // Code blocks (```code```)
        converted = converted.replacingOccurrences(
            of: #"```(\w*)\n([\s\S]*?)```"#,
            with: #"<pre><code>$2</code></pre>"#,
            options: .regularExpression
        )
        
        // Headers
        converted = converted.replacingOccurrences(
            of: #"(?m)^###### (.+)$"#,
            with: #"<h6>$1</h6>"#,
            options: .regularExpression
        )
        converted = converted.replacingOccurrences(
            of: #"(?m)^##### (.+)$"#,
            with: #"<h5>$1</h5>"#,
            options: .regularExpression
        )
        converted = converted.replacingOccurrences(
            of: #"(?m)^#### (.+)$"#,
            with: #"<h4>$1</h4>"#,
            options: .regularExpression
        )
        converted = converted.replacingOccurrences(
            of: #"(?m)^### (.+)$"#,
            with: #"<h3>$1</h3>"#,
            options: .regularExpression
        )
        converted = converted.replacingOccurrences(
            of: #"(?m)^## (.+)$"#,
            with: #"<h2>$1</h2>"#,
            options: .regularExpression
        )
        converted = converted.replacingOccurrences(
            of: #"(?m)^# (.+)$"#,
            with: #"<h1>$1</h1>"#,
            options: .regularExpression
        )
        
        // Bold
        converted = converted.replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#,
            with: #"<strong>$1</strong>"#,
            options: .regularExpression
        )
        
        // Italic
        converted = converted.replacingOccurrences(
            of: #"\*(.+?)\*"#,
            with: #"<em>$1</em>"#,
            options: .regularExpression
        )
        
        // Inline code
        converted = converted.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: #"<code>$1</code>"#,
            options: .regularExpression
        )
        
        // Links
        converted = converted.replacingOccurrences(
            of: #"\[([^\]]+)\]\(([^)]+)\)"#,
            with: #"<a href=\"$2\">$1</a>"#,
            options: .regularExpression
        )
        
        // Images
        converted = converted.replacingOccurrences(
            of: #"!\[([^\]]*)\]\(([^)]+)\)"#,
            with: #"<img src=\"$2\" alt=\"$1\">"#,
            options: .regularExpression
        )
        
        // Unordered lists
        converted = converted.replacingOccurrences(
            of: #"(?m)^[\*\-] (.+)$"#,
            with: #"<li>$1</li>"#,
            options: .regularExpression
        )
        converted = converted.replacingOccurrences(
            of: #"(<li>.*</li>\n?)+"#,
            with: #"<ul>$0</ul>"#,
            options: .regularExpression
        )
        
        // Ordered lists
        converted = converted.replacingOccurrences(
            of: #"(?m)^\d+\. (.+)$"#,
            with: #"<li>$1</li>"#,
            options: .regularExpression
        )
        
        // Horizontal rule
        converted = converted.replacingOccurrences(
            of: #"(?m)^[\*\-]{3,}$"#,
            with: #"<hr>"#,
            options: .regularExpression
        )
        
        // Paragraphs (double newlines)
        converted = converted.replacingOccurrences(
            of: #"\n\n+"#,
            with: #"</p><p>"#,
            options: .regularExpression
        )
        
        // Wrap in paragraph if not already wrapped
        if !converted.hasPrefix("<h") && !converted.hasPrefix("<ul") && !converted.hasPrefix("<ol") && !converted.hasPrefix("<pre") {
            converted = "<p>" + converted + "</p>"
        }
        
        html += converted
        html += """
        </body>
        </html>
        """
        
        return html
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow internal navigation (loading HTML)
            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
                return
            }
            // Open external links in default browser
            if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
