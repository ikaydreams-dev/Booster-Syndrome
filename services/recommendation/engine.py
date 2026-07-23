import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from collections import defaultdict

class RecommendationEngine:
    def __init__(self):
        self.user_item_matrix = None
        self.item_similarity = None
        self.user_profiles = {}

    def build_matrix(self, interactions):
        """Build user-item interaction matrix"""
        users = list(set([i['user_id'] for i in interactions]))
        items = list(set([i['item_id'] for i in interactions]))

        matrix = np.zeros((len(users), len(items)))

        user_idx = {u: i for i, u in enumerate(users)}
        item_idx = {it: i for i, it in enumerate(items)}

        for interaction in interactions:
            u_idx = user_idx[interaction['user_id']]
            i_idx = item_idx[interaction['item_id']]
            matrix[u_idx][i_idx] = interaction.get('rating', 1)

        self.user_item_matrix = matrix
        return matrix

    def calculate_similarity(self):
        """Calculate item-item similarity"""
        self.item_similarity = cosine_similarity(self.user_item_matrix.T)

    def recommend_items(self, user_id, n=10):
        """Generate top N recommendations for user"""
        if user_id not in self.user_profiles:
            return []

        user_vector = self.user_profiles[user_id]
        scores = self.item_similarity.dot(user_vector)

        top_indices = np.argsort(scores)[-n:][::-1]
        return top_indices.tolist()

    def collaborative_filtering(self, user_id, n=10):
        """Collaborative filtering recommendations"""
        recommendations = []
        # Implementation here
        return recommendations

    def content_based_filtering(self, user_id, n=10):
        """Content-based recommendations"""
        recommendations = []
        # Implementation here
        return recommendations
