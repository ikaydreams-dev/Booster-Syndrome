from reportlab.lib.pagesizes import letter, A4
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
import io

class PDFGenerator:
    def __init__(self):
        self.styles = getSampleStyleSheet()

    def generate_invoice(self, invoice_data):
        """Generate invoice PDF"""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter)

        elements = []

        # Title
        title = Paragraph("INVOICE", self.styles['Title'])
        elements.append(title)
        elements.append(Spacer(1, 0.2*inch))

        # Invoice details
        details = [
            ['Invoice #:', invoice_data.get('invoice_number')],
            ['Date:', invoice_data.get('date')],
            ['Customer:', invoice_data.get('customer_name')]
        ]

        details_table = Table(details)
        details_table.setStyle(TableStyle([
            ('FONT', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 12),
            ('PADDING', (0, 0), (-1, -1), 6)
        ]))

        elements.append(details_table)
        elements.append(Spacer(1, 0.3*inch))

        # Items table
        items = [['Description', 'Quantity', 'Price', 'Total']]
        for item in invoice_data.get('items', []):
            items.append([
                item['description'],
                str(item['quantity']),
                f"${item['price']:.2f}",
                f"${item['quantity'] * item['price']:.2f}"
            ])

        items_table = Table(items)
        items_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 14),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))

        elements.append(items_table)

        doc.build(elements)
        buffer.seek(0)
        return buffer.getvalue()

    def generate_report(self, report_data):
        """Generate data report PDF"""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4)

        elements = []

        title = Paragraph(report_data.get('title', 'Report'), self.styles['Title'])
        elements.append(title)
        elements.append(Spacer(1, 0.3*inch))

        for section in report_data.get('sections', []):
            heading = Paragraph(section['heading'], self.styles['Heading2'])
            elements.append(heading)

            content = Paragraph(section['content'], self.styles['BodyText'])
            elements.append(content)
            elements.append(Spacer(1, 0.2*inch))

        doc.build(elements)
        buffer.seek(0)
        return buffer.getvalue()
