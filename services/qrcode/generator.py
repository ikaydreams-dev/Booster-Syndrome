import qrcode
import io

class QRCodeGenerator:
    def generate(self, data, size=10):
        """Generate QR code"""
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=size,
            border=4,
        )

        qr.add_data(data)
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white")

        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        return buffer.getvalue()

    def generate_with_logo(self, data, logo_path):
        """Generate QR code with logo"""
        qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_H)
        qr.add_data(data)
        qr.make()

        img = qr.make_image().convert('RGB')

        # Add logo logic here

        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        return buffer.getvalue()
