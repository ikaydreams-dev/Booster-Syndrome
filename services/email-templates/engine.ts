import Handlebars from 'handlebars';

export interface EmailTemplate {
  name: string;
  subject: string;
  html: string;
  text?: string;
}

export class EmailTemplateEngine {
  private templates: Map<string, EmailTemplate>;

  constructor() {
    this.templates = new Map();
    this.registerHelpers();
  }

  registerTemplate(template: EmailTemplate): void {
    this.templates.set(template.name, template);
  }

  render(templateName: string, data: Record<string, any>): { subject: string; html: string; text: string } {
    const template = this.templates.get(templateName);

    if (!template) {
      throw new Error(`Template ${templateName} not found`);
    }

    const compiledSubject = Handlebars.compile(template.subject);
    const compiledHtml = Handlebars.compile(template.html);
    const compiledText = template.text ? Handlebars.compile(template.text) : null;

    return {
      subject: compiledSubject(data),
      html: compiledHtml(data),
      text: compiledText ? compiledText(data) : this.htmlToText(compiledHtml(data)),
    };
  }

  private registerHelpers(): void {
    Handlebars.registerHelper('formatDate', (date: Date) => {
      return date.toLocaleDateString();
    });

    Handlebars.registerHelper('uppercase', (str: string) => {
      return str.toUpperCase();
    });

    Handlebars.registerHelper('lowercase', (str: string) => {
      return str.toLowerCase();
    });

    Handlebars.registerHelper('currency', (amount: number) => {
      return `$${amount.toFixed(2)}`;
    });
  }

  private htmlToText(html: string): string {
    return html
      .replace(/<[^>]*>/g, '')
      .replace(/&nbsp;/g, ' ')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&');
  }
}

export const defaultTemplates: EmailTemplate[] = [
  {
    name: 'welcome',
    subject: 'Welcome to {{appName}}!',
    html: `
      <h1>Welcome, {{userName}}!</h1>
      <p>Thank you for joining {{appName}}.</p>
      <p><a href="{{verificationUrl}}">Verify your email</a></p>
    `,
    text: 'Welcome, {{userName}}! Thank you for joining {{appName}}. Verify your email: {{verificationUrl}}',
  },
  {
    name: 'password-reset',
    subject: 'Password Reset Request',
    html: `
      <h1>Password Reset</h1>
      <p>Click the link below to reset your password:</p>
      <p><a href="{{resetUrl}}">Reset Password</a></p>
      <p>This link expires in 1 hour.</p>
    `,
    text: 'Password Reset: {{resetUrl}} (expires in 1 hour)',
  },
  {
    name: 'notification',
    subject: 'New Notification',
    html: `
      <h2>{{notificationTitle}}</h2>
      <p>{{notificationMessage}}</p>
      <p><a href="{{actionUrl}}">View Details</a></p>
    `,
  },
];

export function createEmailEngine(): EmailTemplateEngine {
  const engine = new EmailTemplateEngine();

  defaultTemplates.forEach((template) => {
    engine.registerTemplate(template);
  });

  return engine;
}
