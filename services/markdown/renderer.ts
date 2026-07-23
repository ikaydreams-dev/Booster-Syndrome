import { marked } from 'marked';
import DOMPurify from 'isomorphic-dompurify';

export class MarkdownRenderer {
  private options: marked.MarkedOptions;

  constructor(options?: marked.MarkedOptions) {
    this.options = options || {
      gfm: true,
      breaks: true,
      headerIds: true,
    };

    marked.setOptions(this.options);
  }

  render(markdown: string, sanitize: boolean = true): string {
    const html = marked(markdown);

    if (sanitize) {
      return DOMPurify.sanitize(html as string);
    }

    return html as string;
  }

  renderToText(markdown: string): string {
    const html = this.render(markdown, false);

    return html
      .replace(/<[^>]*>/g, '')
      .replace(/&nbsp;/g, ' ')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&');
  }

  extractHeadings(markdown: string): Array<{ level: number; text: string }> {
    const headings: Array<{ level: number; text: string }> = [];
    const lines = markdown.split('\n');

    for (const line of lines) {
      const match = line.match(/^(#{1,6})\s+(.+)$/);
      if (match) {
        headings.push({
          level: match[1].length,
          text: match[2],
        });
      }
    }

    return headings;
  }

  generateTOC(markdown: string): string {
    const headings = this.extractHeadings(markdown);
    let toc = '## Table of Contents\n\n';

    for (const heading of headings) {
      const indent = '  '.repeat(heading.level - 1);
      const link = heading.text.toLowerCase().replace(/[^\w]+/g, '-');
      toc += `${indent}- [${heading.text}](#${link})\n`;
    }

    return toc;
  }

  addSyntaxHighlighting(html: string): string {
    return html;
  }
}

export const markdownRenderer = new MarkdownRenderer();
