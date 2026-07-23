import pytesseract
from PIL import Image
import cv2
import numpy as np

class OCRService:
    def __init__(self):
        self.config = '--oem 3 --psm 6'

    def extract_text(self, image_path: str) -> str:
        """Extract text from image"""
        image = Image.open(image_path)
        text = pytesseract.image_to_string(image, config=self.config)
        return text.strip()

    def extract_with_confidence(self, image_path: str) -> list:
        """Extract text with confidence scores"""
        image = Image.open(image_path)
        data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)

        results = []
        for i in range(len(data['text'])):
            if int(data['conf'][i]) > 0:
                results.append({
                    'text': data['text'][i],
                    'confidence': int(data['conf'][i]),
                    'box': {
                        'x': data['left'][i],
                        'y': data['top'][i],
                        'width': data['width'][i],
                        'height': data['height'][i]
                    }
                })

        return results

    def preprocess_image(self, image_path: str) -> np.ndarray:
        """Preprocess image for better OCR"""
        img = cv2.imread(image_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        denoised = cv2.fastNlMeansDenoising(gray)
        _, thresh = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        return thresh

    def extract_from_preprocessed(self, image_path: str) -> str:
        """Extract text after preprocessing"""
        processed = self.preprocess_image(image_path)
        text = pytesseract.image_to_string(processed, config=self.config)
        return text.strip()

ocr_service = OCRService()
