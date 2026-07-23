import markdown
from markdown.extensions import tables, fenced_code, codehilite

class MarkdownRenderer:
    def __init__(self):
        self.md = markdown.Markdown(extensions=[
            'tables',
            'fenced_code',
            'codehilite',
            'nl2br',
            'sane_lists'
        ])

    def render(self, text):
        """Convert markdown to HTML"""
        return self.md.convert(text)

    def render_with_toc(self, text):
        """Render with table of contents"""
        md = markdown.Markdown(extensions=[
            'toc',
            'tables',
            'fenced_code'
        ])

        html = md.convert(text)
        toc = md.toc

        return {
            'html': html,
            'toc': toc
        }

    def sanitize_html(self, html):
        """Sanitize HTML output"""
        import bleach

        allowed_tags = ['p', 'br', 'strong', 'em', 'u', 'h1', 'h2', 'h3',
                        'ul', 'ol', 'li', 'a', 'code', 'pre', 'blockquote']

        allowed_attrs = {'a': ['href', 'title']}

        return bleach.clean(html, tags=allowed_tags, attributes=allowed_attrs)
