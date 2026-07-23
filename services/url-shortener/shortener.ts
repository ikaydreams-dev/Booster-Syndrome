import crypto from 'crypto';

interface ShortUrl {
  id: string;
  originalUrl: string;
  shortCode: string;
  createdAt: Date;
  expiresAt?: Date;
  clicks: number;
}

export class URLShortenerService {
  private urls: Map<string, ShortUrl> = new Map();
  private baseUrl: string;

  constructor(baseUrl: string = 'https://short.url') {
    this.baseUrl = baseUrl;
  }

  generateShortCode(length: number = 6): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let code = '';

    for (let i = 0; i < length; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }

    return code;
  }

  async createShortUrl(originalUrl: string, customCode?: string, expiresIn?: number): Promise<ShortUrl> {
    const shortCode = customCode || this.generateShortCode();

    if (this.urls.has(shortCode)) {
      throw new Error('Short code already exists');
    }

    const shortUrl: ShortUrl = {
      id: crypto.randomUUID(),
      originalUrl,
      shortCode,
      createdAt: new Date(),
      expiresAt: expiresIn ? new Date(Date.now() + expiresIn) : undefined,
      clicks: 0,
    };

    this.urls.set(shortCode, shortUrl);

    return shortUrl;
  }

  async getOriginalUrl(shortCode: string): Promise<string | null> {
    const shortUrl = this.urls.get(shortCode);

    if (!shortUrl) {
      return null;
    }

    if (shortUrl.expiresAt && new Date() > shortUrl.expiresAt) {
      this.urls.delete(shortCode);
      return null;
    }

    shortUrl.clicks++;

    return shortUrl.originalUrl;
  }

  getFullShortUrl(shortCode: string): string {
    return `${this.baseUrl}/${shortCode}`;
  }

  async getStats(shortCode: string): Promise<ShortUrl | null> {
    return this.urls.get(shortCode) || null;
  }

  async deleteShortUrl(shortCode: string): Promise<boolean> {
    return this.urls.delete(shortCode);
  }

  async getAllUrls(): Promise<ShortUrl[]> {
    return Array.from(this.urls.values());
  }

  cleanupExpired(): number {
    const now = new Date();
    let count = 0;

    for (const [code, url] of this.urls.entries()) {
      if (url.expiresAt && now > url.expiresAt) {
        this.urls.delete(code);
        count++;
      }
    }

    return count;
  }
}

export const urlShortener = new URLShortenerService();
