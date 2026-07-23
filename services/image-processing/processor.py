from PIL import Image
import io
import base64

class ImageProcessor:
    def __init__(self):
        self.supported_formats = ['JPEG', 'PNG', 'GIF', 'WEBP']

    def resize_image(self, image_data, width, height):
        """Resize image to specified dimensions"""
        img = Image.open(io.BytesIO(image_data))
        img = img.resize((width, height), Image.LANCZOS)

        output = io.BytesIO()
        img.save(output, format=img.format)
        return output.getvalue()

    def create_thumbnail(self, image_data, size=200):
        """Create square thumbnail"""
        img = Image.open(io.BytesIO(image_data))
        img.thumbnail((size, size), Image.LANCZOS)

        output = io.BytesIO()
        img.save(output, format=img.format or 'JPEG')
        return output.getvalue()

    def convert_format(self, image_data, target_format):
        """Convert image to different format"""
        img = Image.open(io.BytesIO(image_data))

        if img.mode in ('RGBA', 'LA') and target_format == 'JPEG':
            background = Image.new('RGB', img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[-1])
            img = background

        output = io.BytesIO()
        img.save(output, format=target_format)
        return output.getvalue()

    def optimize_image(self, image_data, quality=85):
        """Optimize image size"""
        img = Image.open(io.BytesIO(image_data))

        output = io.BytesIO()
        img.save(output, format=img.format, optimize=True, quality=quality)
        return output.getvalue()

    def get_metadata(self, image_data):
        """Extract image metadata"""
        img = Image.open(io.BytesIO(image_data))

        return {
            'format': img.format,
            'mode': img.mode,
            'size': img.size,
            'width': img.width,
            'height': img.height
        }
