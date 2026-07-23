from jinja2 import Environment, FileSystemLoader, Template
from typing import Dict, Any
import os

class TemplateEngine:
    def __init__(self, templates_dir: str):
        self.templates_dir = templates_dir
        self.env = Environment(loader=FileSystemLoader(templates_dir))

    def render(self, template_name: str, context: Dict[str, Any]) -> str:
        """Render a template with given context"""
        template = self.env.get_template(template_name)
        return template.render(**context)

    def render_string(self, template_string: str, context: Dict[str, Any]) -> str:
        """Render a template string with given context"""
        template = Template(template_string)
        return template.render(**context)

    def add_filter(self, name: str, func):
        """Add custom filter to template engine"""
        self.env.filters[name] = func

    def add_global(self, name: str, value: Any):
        """Add global variable to template engine"""
        self.env.globals[name] = value

class HTMLTemplateEngine(TemplateEngine):
    def __init__(self, templates_dir: str):
        super().__init__(templates_dir)
        self.add_filter('currency', lambda x: f'${x:.2f}')
        self.add_filter('percentage', lambda x: f'{x:.1f}%')

class EmailTemplateEngine(TemplateEngine):
    def __init__(self, templates_dir: str):
        super().__init__(templates_dir)
        self.add_filter('bold', lambda x: f'<strong>{x}</strong>')
        self.add_filter('italic', lambda x: f'<em>{x}</em>')

    def render_email(self, template_name: str, context: Dict[str, Any]) -> Dict[str, str]:
        """Render email template with subject and body"""
        content = self.render(template_name, context)

        lines = content.split('\n')
        subject = lines[0].replace('Subject: ', '') if lines else ''
        body = '\n'.join(lines[1:]) if len(lines) > 1 else ''

        return {
            'subject': subject,
            'body': body
        }
