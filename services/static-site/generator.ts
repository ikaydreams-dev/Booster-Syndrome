import fs from 'fs';
import path from 'path';
import { marked } from 'marked';

export interface PageMetadata {
  title: string;
  description?: string;
  date?: Date;
  author?: string;
  tags?: string[];
  layout?: string;
}

export interface Page {
  metadata: PageMetadata;
  content: string;
  slug: string;
}

export class StaticSiteGenerator {
  private pagesDir: string;
  private outputDir: string;
  private layoutsDir: string;

  constructor(pagesDir: string, outputDir: string, layoutsDir: string) {
    this.pagesDir = pagesDir;
    this.outputDir = outputDir;
    this.layoutsDir = layoutsDir;
  }

  async build(): Promise<void> {
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }

    const pages = await this.loadPages();

    for (const page of pages) {
      await this.generatePage(page);
    }

    await this.generateIndex(pages);
  }

  private async loadPages(): Promise<Page[]> {
    const pages: Page[] = [];
    const files = fs.readdirSync(this.pagesDir);

    for (const file of files) {
      if (file.endsWith('.md')) {
        const filePath = path.join(this.pagesDir, file);
        const content = fs.readFileSync(filePath, 'utf-8');

        const { metadata, body } = this.parseMarkdown(content);
        const slug = file.replace('.md', '');

        pages.push({ metadata, content: body, slug });
      }
    }

    return pages;
  }

  private parseMarkdown(content: string): { metadata: PageMetadata; body: string } {
    const metadataRegex = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/;
    const match = content.match(metadataRegex);

    if (!match) {
      return {
        metadata: { title: 'Untitled' },
        body: content,
      };
    }

    const metadataStr = match[1];
    const body = match[2];

    const metadata: any = {};

    metadataStr.split('\n').forEach((line) => {
      const [key, ...values] = line.split(':');
      if (key && values.length > 0) {
        const value = values.join(':').trim();
        metadata[key.trim()] = value;
      }
    });

    return { metadata, body };
  }

  private async generatePage(page: Page): Promise<void> {
    const html = marked(page.content);
    const layout = this.loadLayout(page.metadata.layout || 'default');

    const finalHtml = this.applyLayout(layout, {
      title: page.metadata.title,
      content: html,
      description: page.metadata.description || '',
      author: page.metadata.author || '',
      date: page.metadata.date?.toString() || '',
    });

    const outputPath = path.join(this.outputDir, `${page.slug}.html`);
    fs.writeFileSync(outputPath, finalHtml);
  }

  private loadLayout(layoutName: string): string {
    const layoutPath = path.join(this.layoutsDir, `${layoutName}.html`);

    if (fs.existsSync(layoutPath)) {
      return fs.readFileSync(layoutPath, 'utf-8');
    }

    return this.defaultLayout();
  }

  private defaultLayout(): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{title}}</title>
  <meta name="description" content="{{description}}">
</head>
<body>
  <main>
    <h1>{{title}}</h1>
    <div>{{content}}</div>
  </main>
</body>
</html>`;
  }

  private applyLayout(layout: string, data: Record<string, string>): string {
    let result = layout;

    for (const [key, value] of Object.entries(data)) {
      result = result.replace(new RegExp(`{{${key}}}`, 'g'), value);
    }

    return result;
  }

  private async generateIndex(pages: Page[]): Promise<void> {
    const links = pages
      .map((page) => `<li><a href="${page.slug}.html">${page.metadata.title}</a></li>`)
      .join('\n');

    const indexHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Index</title>
</head>
<body>
  <h1>Pages</h1>
  <ul>
    ${links}
  </ul>
</body>
</html>`;

    const indexPath = path.join(this.outputDir, 'index.html');
    fs.writeFileSync(indexPath, indexHtml);
  }
}
