from textblob import TextBlob
from typing import Dict, List

class TextAnalysisService:
    def analyze_sentiment(self, text: str) -> Dict[str, float]:
        """Analyze sentiment of text"""
        blob = TextBlob(text)
        sentiment = blob.sentiment

        return {
            'polarity': sentiment.polarity,
            'subjectivity': sentiment.subjectivity
        }

    def extract_keywords(self, text: str, top_n: int = 10) -> List[tuple]:
        """Extract keywords from text"""
        blob = TextBlob(text)
        words = blob.word_counts

        sorted_words = sorted(words.items(), key=lambda x: x[1], reverse=True)
        return sorted_words[:top_n]

    def detect_language(self, text: str) -> str:
        """Detect language of text"""
        blob = TextBlob(text)
        return blob.detect_language()

    def translate_text(self, text: str, target_lang: str = 'es') -> str:
        """Translate text to target language"""
        blob = TextBlob(text)
        return str(blob.translate(to=target_lang))

    def extract_noun_phrases(self, text: str) -> List[str]:
        """Extract noun phrases from text"""
        blob = TextBlob(text)
        return list(blob.noun_phrases)

    def correct_spelling(self, text: str) -> str:
        """Correct spelling in text"""
        blob = TextBlob(text)
        return str(blob.correct())

    def tokenize_sentences(self, text: str) -> List[str]:
        """Split text into sentences"""
        blob = TextBlob(text)
        return [str(s) for s in blob.sentences]

    def tokenize_words(self, text: str) -> List[str]:
        """Split text into words"""
        blob = TextBlob(text)
        return blob.words

    def classify_sentiment(self, text: str) -> str:
        """Classify sentiment as positive, negative, or neutral"""
        sentiment = self.analyze_sentiment(text)
        polarity = sentiment['polarity']

        if polarity > 0.1:
            return 'positive'
        elif polarity < -0.1:
            return 'negative'
        else:
            return 'neutral'

text_analysis = TextAnalysisService()
