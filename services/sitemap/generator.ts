import fs from 'fs';
import path from 'path';

interface SitemapUrl {
  loc: string;
  lastmod?: string;
  changefreq?: 'always' | 'hourly' | 'daily' | 'weekly' | 'monthly' | 'yearly' | 'never';
  priority?: number;
}

export class SitemapGenerator {
  private urls: SitemapUrl[] = [];

  addUrl(url: SitemapUrl): void {
    this.urls.push(url);
  }

  addUrls(urls: SitemapUrl[]): void {
    this.urls.push(...urls);
  }

  generate(): string {
    let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';

    for (const url of this.urls) {
      xml += '  <url>\n';
      xml += `    <loc>${this.escapeXml(url.loc)}</loc>\n`;

      if (url.lastmod) {
        xml += `    <lastmod>${url.lastmod}</lastmod>\n`;
      }

      if (url.changefreq) {
        xml += `    <changefreq>${url.changefreq}</changefreq>\n`;
      }

      if (url.priority !== undefined) {
        xml += `    <priority>${url.priority}</priority>\n`;
      }

      xml += '  </url>\n';
    }

    xml += '</urlset>';

    return xml;
  }

  async saveToFile(filePath: string): Promise<void> {
    const xml = this.generate();
    fs.writeFileSync(filePath, xml, 'utf-8');
  }

  private escapeXml(str: string): string {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }

  clear(): void {
    this.urls = [];
  }

  static async generateFromRoutes(routes: string[], baseUrl: string): Promise<string> {
    const generator = new SitemapGenerator();

    for (const route of routes) {
      generator.addUrl({
        loc: `${baseUrl}${route}`,
        lastmod: new Date().toISOString(),
        changefreq: 'weekly',
        priority: route === '/' ? 1.0 : 0.8,
      });
    }

    return generator.generate();
  }
}

export const sitemapGenerator = new SitemapGenerator();
