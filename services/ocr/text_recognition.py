import pytesseract
from PIL import Image
import io

class OCRService:
    def __init__(self):
        self.supported_languages = ['eng', 'fra', 'deu', 'spa']

    def extract_text(self, image_data, language='eng'):
        """Extract text from image"""
        img = Image.open(io.BytesIO(image_data))

        text = pytesseract.image_to_string(img, lang=language)

        return {
            'text': text,
            'language': language
        }

    def extract_with_boxes(self, image_data):
        """Extract text with bounding boxes"""
        img = Image.open(io.BytesIO(image_data))

        data = pytesseract.image_to_data(img, output_type=pytesseract.Output.DICT)

        results = []
        for i in range(len(data['text'])):
            if data['text'][i].strip():
                results.append({
                    'text': data['text'][i],
                    'confidence': data['conf'][i],
                    'box': {
                        'x': data['left'][i],
                        'y': data['top'][i],
                        'width': data['width'][i],
                        'height': data['height'][i]
                    }
                })

        return results

    def detect_orientation(self, image_data):
        """Detect image orientation"""
        img = Image.open(io.BytesIO(image_data))

        osd = pytesseract.image_to_osd(img)

        return {
            'orientation': osd,
            'rotate': 0
        }
