from typing import List, Dict
import numpy as np
from collections import defaultdict

class CollaborativeFilteringEngine:
    def __init__(self):
        self.user_ratings: Dict[str, Dict[str, float]] = defaultdict(dict)
        self.item_ratings: Dict[str, Dict[str, float]] = defaultdict(dict)

    def add_rating(self, user_id: str, item_id: str, rating: float):
        """Add user rating for an item"""
        self.user_ratings[user_id][item_id] = rating
        self.item_ratings[item_id][user_id] = rating

    def get_recommendations(self, user_id: str, num_recommendations: int = 10) -> List[tuple]:
        """Get personalized recommendations for a user"""
        if user_id not in self.user_ratings:
            return []

        user_items = set(self.user_ratings[user_id].keys())
        predictions = {}

        for item_id in self.item_ratings:
            if item_id not in user_items:
                predicted_rating = self.predict_rating(user_id, item_id)
                if predicted_rating > 0:
                    predictions[item_id] = predicted_rating

        sorted_predictions = sorted(predictions.items(), key=lambda x: x[1], reverse=True)
        return sorted_predictions[:num_recommendations]

    def predict_rating(self, user_id: str, item_id: str) -> float:
        """Predict rating for user-item pair"""
        if user_id not in self.user_ratings or item_id not in self.item_ratings:
            return 0.0

        similar_users = self.find_similar_users(user_id, limit=10)
        weighted_sum = 0.0
        similarity_sum = 0.0

        for similar_user, similarity in similar_users:
            if item_id in self.user_ratings[similar_user]:
                weighted_sum += similarity * self.user_ratings[similar_user][item_id]
                similarity_sum += similarity

        if similarity_sum == 0:
            return 0.0

        return weighted_sum / similarity_sum

    def find_similar_users(self, user_id: str, limit: int = 10) -> List[tuple]:
        """Find most similar users using Pearson correlation"""
        similarities = []

        for other_user_id in self.user_ratings:
            if other_user_id == user_id:
                continue

            similarity = self.pearson_correlation(user_id, other_user_id)
            if similarity > 0:
                similarities.append((other_user_id, similarity))

        similarities.sort(key=lambda x: x[1], reverse=True)
        return similarities[:limit]

    def pearson_correlation(self, user1: str, user2: str) -> float:
        """Calculate Pearson correlation between two users"""
        common_items = set(self.user_ratings[user1].keys()) & set(self.user_ratings[user2].keys())

        if len(common_items) == 0:
            return 0.0

        ratings1 = [self.user_ratings[user1][item] for item in common_items]
        ratings2 = [self.user_ratings[user2][item] for item in common_items]

        mean1 = sum(ratings1) / len(ratings1)
        mean2 = sum(ratings2) / len(ratings2)

        numerator = sum((r1 - mean1) * (r2 - mean2) for r1, r2 in zip(ratings1, ratings2))
        denominator1 = sum((r1 - mean1) ** 2 for r1 in ratings1) ** 0.5
        denominator2 = sum((r2 - mean2) ** 2 for r2 in ratings2) ** 0.5

        if denominator1 == 0 or denominator2 == 0:
            return 0.0

        return numerator / (denominator1 * denominator2)

cf_engine = CollaborativeFilteringEngine()
