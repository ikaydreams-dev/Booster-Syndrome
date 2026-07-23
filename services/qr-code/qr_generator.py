import qrcode
from io import BytesIO
from typing import Optional

class QRCodeGenerator:
    def __init__(self, version: int = 1, box_size: int = 10, border: int = 4):
        self.version = version
        self.box_size = box_size
        self.border = border

    def generate(self, data: str, fill_color: str = 'black', back_color: str = 'white') -> bytes:
        """Generate QR code as PNG bytes"""
        qr = qrcode.QRCode(
            version=self.version,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=self.box_size,
            border=self.border,
        )

        qr.add_data(data)
        qr.make(fit=True)

        img = qr.make_image(fill_color=fill_color, back_color=back_color)

        buffer = BytesIO()
        img.save(buffer, format='PNG')
        return buffer.getvalue()

    def generate_to_file(self, data: str, file_path: str, fill_color: str = 'black', back_color: str = 'white'):
        """Generate QR code and save to file"""
        qr = qrcode.QRCode(
            version=self.version,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=self.box_size,
            border=self.border,
        )

        qr.add_data(data)
        qr.make(fit=True)

        img = qr.make_image(fill_color=fill_color, back_color=back_color)
        img.save(file_path)

    def generate_url_qr(self, url: str) -> bytes:
        """Generate QR code for URL"""
        return self.generate(url)

    def generate_vcard_qr(self, name: str, phone: str, email: str) -> bytes:
        """Generate QR code for vCard"""
        vcard = f"""BEGIN:VCARD
VERSION:3.0
FN:{name}
TEL:{phone}
EMAIL:{email}
END:VCARD"""
        return self.generate(vcard)

    def generate_wifi_qr(self, ssid: str, password: str, security: str = 'WPA') -> bytes:
        """Generate QR code for WiFi"""
        wifi_string = f"WIFI:T:{security};S:{ssid};P:{password};;"
        return self.generate(wifi_string)

qr_generator = QRCodeGenerator()
