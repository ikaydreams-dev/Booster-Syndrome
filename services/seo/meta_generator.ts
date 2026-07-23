export interface MetaTags {
  title: string;
  description: string;
  keywords?: string[];
  author?: string;
  canonical?: string;
  og?: OpenGraphTags;
  twitter?: TwitterTags;
  robots?: string;
}

export interface OpenGraphTags {
  title: string;
  description: string;
  image: string;
  url: string;
  type?: string;
  siteName?: string;
}

export interface TwitterTags {
  card: 'summary' | 'summary_large_image' | 'app' | 'player';
  site?: string;
  creator?: string;
  title: string;
  description: string;
  image?: string;
}

export class SEOMetaGenerator {
  static generateMetaTags(meta: MetaTags): string {
    let html = '';

    html += `<title>${this.escape(meta.title)}</title>\n`;
    html += `<meta name="description" content="${this.escape(meta.description)}" />\n`;

    if (meta.keywords && meta.keywords.length > 0) {
      html += `<meta name="keywords" content="${meta.keywords.join(', ')}" />\n`;
    }

    if (meta.author) {
      html += `<meta name="author" content="${this.escape(meta.author)}" />\n`;
    }

    if (meta.canonical) {
      html += `<link rel="canonical" href="${this.escape(meta.canonical)}" />\n`;
    }

    if (meta.robots) {
      html += `<meta name="robots" content="${meta.robots}" />\n`;
    }

    if (meta.og) {
      html += this.generateOpenGraphTags(meta.og);
    }

    if (meta.twitter) {
      html += this.generateTwitterTags(meta.twitter);
    }

    return html;
  }

  static generateOpenGraphTags(og: OpenGraphTags): string {
    let html = '';

    html += `<meta property="og:title" content="${this.escape(og.title)}" />\n`;
    html += `<meta property="og:description" content="${this.escape(og.description)}" />\n`;
    html += `<meta property="og:image" content="${this.escape(og.image)}" />\n`;
    html += `<meta property="og:url" content="${this.escape(og.url)}" />\n`;

    if (og.type) {
      html += `<meta property="og:type" content="${og.type}" />\n`;
    }

    if (og.siteName) {
      html += `<meta property="og:site_name" content="${this.escape(og.siteName)}" />\n`;
    }

    return html;
  }

  static generateTwitterTags(twitter: TwitterTags): string {
    let html = '';

    html += `<meta name="twitter:card" content="${twitter.card}" />\n`;
    html += `<meta name="twitter:title" content="${this.escape(twitter.title)}" />\n`;
    html += `<meta name="twitter:description" content="${this.escape(twitter.description)}" />\n`;

    if (twitter.site) {
      html += `<meta name="twitter:site" content="${twitter.site}" />\n`;
    }

    if (twitter.creator) {
      html += `<meta name="twitter:creator" content="${twitter.creator}" />\n`;
    }

    if (twitter.image) {
      html += `<meta name="twitter:image" content="${this.escape(twitter.image)}" />\n`;
    }

    return html;
  }

  static generateStructuredData(data: any): string {
    return `<script type="application/ld+json">\n${JSON.stringify(data, null, 2)}\n</script>`;
  }

  static generateBreadcrumbStructuredData(items: Array<{ name: string; url: string }>): string {
    const breadcrumb = {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      itemListElement: items.map((item, index) => ({
        '@type': 'ListItem',
        position: index + 1,
        name: item.name,
        item: item.url,
      })),
    };

    return this.generateStructuredData(breadcrumb);
  }

  private static escape(str: string): string {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}
