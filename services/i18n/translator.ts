export interface Translation {
  [key: string]: string | Translation;
}

export interface Locale {
  code: string;
  name: string;
  translations: Translation;
}

export class I18nService {
  private locales: Map<string, Locale> = new Map();
  private currentLocale: string = 'en';
  private fallbackLocale: string = 'en';

  addLocale(locale: Locale): void {
    this.locales.set(locale.code, locale);
  }

  setLocale(code: string): void {
    if (!this.locales.has(code)) {
      throw new Error(`Locale ${code} not found`);
    }
    this.currentLocale = code;
  }

  setFallbackLocale(code: string): void {
    this.fallbackLocale = code;
  }

  t(key: string, params?: Record<string, string | number>): string {
    let translation = this.getTranslation(key, this.currentLocale);

    if (!translation && this.currentLocale !== this.fallbackLocale) {
      translation = this.getTranslation(key, this.fallbackLocale);
    }

    if (!translation) {
      return key;
    }

    if (params) {
      return this.interpolate(translation, params);
    }

    return translation;
  }

  private getTranslation(key: string, localeCode: string): string | null {
    const locale = this.locales.get(localeCode);
    if (!locale) return null;

    const keys = key.split('.');
    let current: any = locale.translations;

    for (const k of keys) {
      if (current[k] === undefined) return null;
      current = current[k];
    }

    return typeof current === 'string' ? current : null;
  }

  private interpolate(text: string, params: Record<string, string | number>): string {
    let result = text;

    for (const [key, value] of Object.entries(params)) {
      result = result.replace(new RegExp(`{{\\s*${key}\\s*}}`, 'g'), String(value));
    }

    return result;
  }

  getCurrentLocale(): string {
    return this.currentLocale;
  }

  getAvailableLocales(): string[] {
    return Array.from(this.locales.keys());
  }

  hasTranslation(key: string, localeCode?: string): boolean {
    const locale = localeCode || this.currentLocale;
    return this.getTranslation(key, locale) !== null;
  }
}

export const i18n = new I18nService();

i18n.addLocale({
  code: 'en',
  name: 'English',
  translations: {
    common: {
      welcome: 'Welcome',
      goodbye: 'Goodbye',
      hello: 'Hello, {{name}}!',
    },
    errors: {
      notFound: 'Not found',
      unauthorized: 'Unauthorized',
      serverError: 'Server error',
    },
  },
});

i18n.addLocale({
  code: 'es',
  name: 'Español',
  translations: {
    common: {
      welcome: 'Bienvenido',
      goodbye: 'Adiós',
      hello: 'Hola, {{name}}!',
    },
    errors: {
      notFound: 'No encontrado',
      unauthorized: 'No autorizado',
      serverError: 'Error del servidor',
    },
  },
});
