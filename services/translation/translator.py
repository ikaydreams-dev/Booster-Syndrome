from googletrans import Translator

class TranslationService:
    def __init__(self):
        self.translator = Translator()

    def translate_text(self, text, target_language='en', source_language='auto'):
        """Translate text to target language"""
        result = self.translator.translate(
            text,
            dest=target_language,
            src=source_language
        )

        return {
            'original': text,
            'translated': result.text,
            'source_lang': result.src,
            'target_lang': target_language
        }

    def detect_language(self, text):
        """Detect language of text"""
        result = self.translator.detect(text)

        return {
            'language': result.lang,
            'confidence': result.confidence
        }

    def translate_batch(self, texts, target_language='en'):
        """Translate multiple texts"""
        results = []

        for text in texts:
            result = self.translate_text(text, target_language)
            results.append(result)

        return results
