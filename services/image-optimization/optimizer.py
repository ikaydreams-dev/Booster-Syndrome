from PIL import Image
import io
from typing import Tuple, Optional

class ImageOptimizer:
    def __init__(self, quality: int = 85):
        self.quality = quality

    def optimize(self, image_bytes: bytes, format: str = 'JPEG') -> bytes:
        """Optimize image by compressing and converting format"""
        image = Image.open(io.BytesIO(image_bytes))

        if image.mode in ('RGBA', 'LA', 'P'):
            if format.upper() == 'JPEG':
                background = Image.new('RGB', image.size, (255, 255, 255))
                background.paste(image, mask=image.split()[-1] if 'A' in image.mode else None)
                image = background

        output = io.BytesIO()
        image.save(output, format=format, quality=self.quality, optimize=True)
        return output.getvalue()

    def resize(self, image_bytes: bytes, max_width: int, max_height: int) -> bytes:
        """Resize image maintaining aspect ratio"""
        image = Image.open(io.BytesIO(image_bytes))

        image.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)

        output = io.BytesIO()
        format = image.format or 'JPEG'
        image.save(output, format=format, quality=self.quality)
        return output.getvalue()

    def create_thumbnail(self, image_bytes: bytes, size: Tuple[int, int] = (150, 150)) -> bytes:
        """Create thumbnail from image"""
        image = Image.open(io.BytesIO(image_bytes))

        image.thumbnail(size, Image.Resampling.LANCZOS)

        output = io.BytesIO()
        format = image.format or 'JPEG'
        image.save(output, format=format, quality=self.quality)
        return output.getvalue()

    def convert_to_webp(self, image_bytes: bytes) -> bytes:
        """Convert image to WebP format"""
        image = Image.open(io.BytesIO(image_bytes))

        output = io.BytesIO()
        image.save(output, format='WEBP', quality=self.quality)
        return output.getvalue()

    def crop(self, image_bytes: bytes, box: Tuple[int, int, int, int]) -> bytes:
        """Crop image to specified box (left, top, right, bottom)"""
        image = Image.open(io.BytesIO(image_bytes))

        cropped = image.crop(box)

        output = io.BytesIO()
        format = image.format or 'JPEG'
        cropped.save(output, format=format, quality=self.quality)
        return output.getvalue()

    def get_dimensions(self, image_bytes: bytes) -> Tuple[int, int]:
        """Get image dimensions"""
        image = Image.open(io.BytesIO(image_bytes))
        return image.size

    def process_multiple_sizes(self, image_bytes: bytes) -> dict:
        """Process image into multiple sizes"""
        sizes = {
            'thumbnail': (150, 150),
            'small': (300, 300),
            'medium': (600, 600),
            'large': (1200, 1200),
        }

        results = {}

        for size_name, dimensions in sizes.items():
            resized = self.resize(image_bytes, dimensions[0], dimensions[1])
            results[size_name] = resized

        return results
