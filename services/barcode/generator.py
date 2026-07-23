import barcode
from barcode.writer import ImageWriter
from io import BytesIO
from typing import Optional

class BarcodeGenerator:
    def __init__(self):
        self.supported_formats = [
            'code39', 'code128', 'ean', 'ean13', 'ean8',
            'gs1', 'gtin', 'isbn', 'isbn10', 'isbn13',
            'issn', 'jan', 'pzn', 'upc', 'upca'
        ]

    def generate(self, data: str, barcode_type: str = 'code128', add_checksum: bool = True) -> bytes:
        """Generate barcode as PNG bytes"""
        if barcode_type not in self.supported_formats:
            raise ValueError(f"Unsupported barcode type: {barcode_type}")

        barcode_class = barcode.get_barcode_class(barcode_type)
        barcode_instance = barcode_class(data, writer=ImageWriter(), add_checksum=add_checksum)

        buffer = BytesIO()
        barcode_instance.write(buffer)

        return buffer.getvalue()

    def generate_to_file(self, data: str, filename: str, barcode_type: str = 'code128'):
        """Generate barcode and save to file"""
        if barcode_type not in self.supported_formats:
            raise ValueError(f"Unsupported barcode type: {barcode_type}")

        barcode_class = barcode.get_barcode_class(barcode_type)
        barcode_instance = barcode_class(data, writer=ImageWriter())

        barcode_instance.save(filename)

    def generate_ean13(self, data: str) -> bytes:
        """Generate EAN-13 barcode"""
        if len(data) != 12:
            raise ValueError("EAN-13 requires exactly 12 digits")

        return self.generate(data, 'ean13')

    def generate_code128(self, data: str) -> bytes:
        """Generate Code 128 barcode"""
        return self.generate(data, 'code128')

    def generate_upca(self, data: str) -> bytes:
        """Generate UPC-A barcode"""
        if len(data) != 11:
            raise ValueError("UPC-A requires exactly 11 digits")

        return self.generate(data, 'upca')

    def generate_isbn(self, data: str) -> bytes:
        """Generate ISBN barcode"""
        if len(data) not in [10, 13]:
            raise ValueError("ISBN requires 10 or 13 digits")

        barcode_type = 'isbn10' if len(data) == 10 else 'isbn13'
        return self.generate(data, barcode_type, add_checksum=False)

barcode_generator = BarcodeGenerator()
