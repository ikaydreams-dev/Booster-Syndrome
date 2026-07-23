from textblob import TextBlob

class SentimentAnalyzer:
    def analyze_text(self, text):
        """Analyze sentiment of text"""
        blob = TextBlob(text)

        polarity = blob.sentiment.polarity
        subjectivity = blob.sentiment.subjectivity

        if polarity > 0.1:
            sentiment = 'positive'
        elif polarity < -0.1:
            sentiment = 'negative'
        else:
            sentiment = 'neutral'

        return {
            'text': text,
            'sentiment': sentiment,
            'polarity': polarity,
            'subjectivity': subjectivity
        }

    def analyze_batch(self, texts):
        """Analyze sentiment of multiple texts"""
        results = []

        for text in texts:
            result = self.analyze_text(text)
            results.append(result)

        return results

    def get_keywords(self, text):
        """Extract keywords from text"""
        blob = TextBlob(text)

        return {
            'noun_phrases': list(blob.noun_phrases),
            'words': [word.lower() for word in blob.words if len(word) > 3]
        }
