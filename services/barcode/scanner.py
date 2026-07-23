from pyzbar.pyzbar import decode
from PIL import Image
import io

class BarcodeScanner:
    def scan(self, image_data):
        """Scan barcode/QR code from image"""
        img = Image.open(io.BytesIO(image_data))

        decoded_objects = decode(img)

        results = []
        for obj in decoded_objects:
            results.append({
                'type': obj.type,
                'data': obj.data.decode('utf-8'),
                'rect': {
                    'left': obj.rect.left,
                    'top': obj.rect.top,
                    'width': obj.rect.width,
                    'height': obj.rect.height
                }
            })

        return results

    def scan_qr(self, image_data):
        """Scan only QR codes"""
        results = self.scan(image_data)
        return [r for r in results if r['type'] == 'QRCODE']
