from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.lib.units import inch
from reportlab.lib import colors
from io import BytesIO
from typing import List, Dict, Any

class PDFGenerator:
    def __init__(self, page_size=letter):
        self.page_size = page_size
        self.styles = getSampleStyleSheet()

    def create_pdf(self, filename: str, content: List[Dict[str, Any]]) -> str:
        """Create PDF with various content types"""
        doc = SimpleDocTemplate(filename, pagesize=self.page_size)
        story = []

        for item in content:
            if item['type'] == 'heading':
                story.append(Paragraph(item['text'], self.styles['Heading1']))
                story.append(Spacer(1, 12))

            elif item['type'] == 'paragraph':
                story.append(Paragraph(item['text'], self.styles['BodyText']))
                story.append(Spacer(1, 12))

            elif item['type'] == 'table':
                table = Table(item['data'])
                table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                story.append(table)
                story.append(Spacer(1, 12))

        doc.build(story)
        return filename

    def create_invoice(self, invoice_data: Dict[str, Any], filename: str) -> str:
        """Generate invoice PDF"""
        doc = SimpleDocTemplate(filename, pagesize=letter)
        story = []

        story.append(Paragraph('INVOICE', self.styles['Heading1']))
        story.append(Spacer(1, 12))

        story.append(Paragraph(f"Invoice #: {invoice_data['invoice_number']}", self.styles['Normal']))
        story.append(Paragraph(f"Date: {invoice_data['date']}", self.styles['Normal']))
        story.append(Spacer(1, 24))

        story.append(Paragraph('Bill To:', self.styles['Heading2']))
        story.append(Paragraph(invoice_data['customer_name'], self.styles['Normal']))
        story.append(Paragraph(invoice_data['customer_address'], self.styles['Normal']))
        story.append(Spacer(1, 24))

        table_data = [['Item', 'Quantity', 'Price', 'Total']]
        for item in invoice_data['items']:
            table_data.append([
                item['description'],
                str(item['quantity']),
                f"${item['price']:.2f}",
                f"${item['quantity'] * item['price']:.2f}"
            ])

        table_data.append(['', '', 'Subtotal:', f"${invoice_data['subtotal']:.2f}"])
        table_data.append(['', '', 'Tax:', f"${invoice_data['tax']:.2f}"])
        table_data.append(['', '', 'Total:', f"${invoice_data['total']:.2f}"])

        table = Table(table_data)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))

        story.append(table)
        doc.build(story)

        return filename

    def create_report(self, title: str, sections: List[Dict], filename: str) -> str:
        """Generate report PDF"""
        doc = SimpleDocTemplate(filename, pagesize=A4)
        story = []

        story.append(Paragraph(title, self.styles['Title']))
        story.append(Spacer(1, 24))

        for section in sections:
            story.append(Paragraph(section['title'], self.styles['Heading2']))
            story.append(Spacer(1, 12))
            story.append(Paragraph(section['content'], self.styles['BodyText']))
            story.append(Spacer(1, 24))

        doc.build(story)
        return filename

pdf_generator = PDFGenerator()
