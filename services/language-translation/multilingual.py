from googletrans import Translator as GoogleTranslator

class MultilingualService:
    def __init__(self):
        self.translator = GoogleTranslator()
        self.supported_languages = {
            'en': 'English', 'es': 'Spanish', 'fr': 'French',
            'de': 'German', 'it': 'Italian', 'pt': 'Portuguese',
            'ru': 'Russian', 'ja': 'Japanese', 'ko': 'Korean',
            'zh-cn': 'Chinese (Simplified)', 'ar': 'Arabic'
        }

    def translate(self, text: str, dest_lang: str, src_lang: str = 'auto') -> dict:
        """Translate text to destination language"""
        result = self.translator.translate(text, dest=dest_lang, src=src_lang)

        return {
            'original': text,
            'translated': result.text,
            'src_lang': result.src,
            'dest_lang': dest_lang,
            'confidence': getattr(result, 'confidence', None)
        }

    def detect_language(self, text: str) -> dict:
        """Detect language of text"""
        detection = self.translator.detect(text)

        return {
            'language': detection.lang,
            'confidence': detection.confidence
        }

    def translate_batch(self, texts: list, dest_lang: str) -> list:
        """Translate multiple texts"""
        results = []
        for text in texts:
            result = self.translate(text, dest_lang)
            results.append(result)
        return results

multilingual_service = MultilingualService()
