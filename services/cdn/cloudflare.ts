import axios from 'axios';

export class CloudflareCDN {
  private apiToken: string;
  private zoneId: string;
  private baseURL = 'https://api.cloudflare.com/client/v4';

  constructor(apiToken: string, zoneId: string) {
    this.apiToken = apiToken;
    this.zoneId = zoneId;
  }

  private getHeaders() {
    return {
      Authorization: `Bearer ${this.apiToken}`,
      'Content-Type': 'application/json',
    };
  }

  async purgeCache(urls?: string[]): Promise<boolean> {
    const endpoint = `${this.baseURL}/zones/${this.zoneId}/purge_cache`;

    const data = urls ? { files: urls } : { purge_everything: true };

    try {
      const response = await axios.post(endpoint, data, {
        headers: this.getHeaders(),
      });

      return response.data.success;
    } catch (error) {
      console.error('Cache purge failed:', error);
      return false;
    }
  }

  async purgeCacheByTags(tags: string[]): Promise<boolean> {
    const endpoint = `${this.baseURL}/zones/${this.zoneId}/purge_cache`;

    try {
      const response = await axios.post(
        endpoint,
        { tags },
        { headers: this.getHeaders() }
      );

      return response.data.success;
    } catch (error) {
      console.error('Cache purge by tags failed:', error);
      return false;
    }
  }

  async getCacheAnalytics(since: Date, until?: Date): Promise<any> {
    const endpoint = `${this.baseURL}/zones/${this.zoneId}/analytics/dashboard`;

    const params = {
      since: since.toISOString(),
      until: (until || new Date()).toISOString(),
    };

    try {
      const response = await axios.get(endpoint, {
        headers: this.getHeaders(),
        params,
      });

      return response.data.result;
    } catch (error) {
      console.error('Analytics fetch failed:', error);
      return null;
    }
  }

  async createPageRule(
    url: string,
    cacheLevel: 'bypass' | 'basic' | 'simplified' | 'aggressive' | 'cache_everything',
    edgeCacheTtl?: number
  ): Promise<boolean> {
    const endpoint = `${this.baseURL}/zones/${this.zoneId}/pagerules`;

    const actions: any[] = [
      { id: 'cache_level', value: cacheLevel },
    ];

    if (edgeCacheTtl) {
      actions.push({ id: 'edge_cache_ttl', value: edgeCacheTtl });
    }

    const data = {
      targets: [{ target: 'url', constraint: { operator: 'matches', value: url } }],
      actions,
      status: 'active',
    };

    try {
      const response = await axios.post(endpoint, data, {
        headers: this.getHeaders(),
      });

      return response.data.success;
    } catch (error) {
      console.error('Page rule creation failed:', error);
      return false;
    }
  }

  async getCDNURL(assetPath: string, cdnDomain?: string): string {
    const domain = cdnDomain || `cdn.example.com`;
    return `https://${domain}/${assetPath}`;
  }

  async prefetchAssets(urls: string[]): Promise<void> {
    for (const url of urls) {
      try {
        await axios.head(url);
      } catch (error) {
        console.error(`Prefetch failed for ${url}:`, error);
      }
    }
  }
}

export function generateCDNURL(
  assetPath: string,
  cdnDomain: string,
  version?: string
): string {
  const versionParam = version ? `?v=${version}` : '';
  return `https://${cdnDomain}/${assetPath}${versionParam}`;
}

export function setCacheHeaders(maxAge: number = 86400) {
  return {
    'Cache-Control': `public, max-age=${maxAge}`,
    'CDN-Cache-Control': `public, max-age=${maxAge}`,
    'Cloudflare-CDN-Cache-Control': `public, max-age=${maxAge}`,
  };
}
