import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
import joblib
import json

class UserBehaviorPredictor:
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.feature_columns = []

    def load_data(self, filepath):
        """Load user behavior data"""
        df = pd.read_csv(filepath)
        return df

    def prepare_features(self, df):
        """Extract features from raw data"""
        features = pd.DataFrame()

        features['total_events'] = df.groupby('user_id')['event_type'].count()
        features['unique_event_types'] = df.groupby('user_id')['event_type'].nunique()
        features['avg_session_duration'] = df.groupby('user_id')['session_duration'].mean()
        features['days_active'] = df.groupby('user_id')['date'].nunique()
        features['purchase_count'] = df[df['event_type'] == 'purchase'].groupby('user_id').size()
        features['last_activity_days'] = (pd.Timestamp.now() - df.groupby('user_id')['timestamp'].max()).dt.days

        features = features.fillna(0)
        return features

    def train(self, X, y, model_type='random_forest'):
        """Train the prediction model"""
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )

        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)

        if model_type == 'random_forest':
            self.model = RandomForestClassifier(
                n_estimators=100,
                max_depth=10,
                random_state=42
            )
        elif model_type == 'gradient_boosting':
            self.model = GradientBoostingClassifier(
                n_estimators=100,
                learning_rate=0.1,
                random_state=42
            )

        self.model.fit(X_train_scaled, y_train)

        y_pred = self.model.predict(X_test_scaled)

        metrics = {
            'accuracy': accuracy_score(y_test, y_pred),
            'precision': precision_score(y_test, y_pred, average='weighted'),
            'recall': recall_score(y_test, y_pred, average='weighted'),
            'f1_score': f1_score(y_test, y_pred, average='weighted')
        }

        return metrics

    def predict(self, X):
        """Make predictions"""
        X_scaled = self.scaler.transform(X)
        predictions = self.model.predict(X_scaled)
        probabilities = self.model.predict_proba(X_scaled)
        return predictions, probabilities

    def save_model(self, filepath):
        """Save trained model"""
        joblib.dump({
            'model': self.model,
            'scaler': self.scaler,
            'feature_columns': self.feature_columns
        }, filepath)

    def load_model(self, filepath):
        """Load trained model"""
        data = joblib.load(filepath)
        self.model = data['model']
        self.scaler = data['scaler']
        self.feature_columns = data['feature_columns']

class ChurnPredictor:
    def __init__(self):
        self.model = RandomForestClassifier(n_estimators=200, max_depth=15)

    def extract_churn_features(self, user_events):
        """Extract features that indicate churn risk"""
        features = {}

        features['days_since_last_login'] = (pd.Timestamp.now() - user_events['timestamp'].max()).days
        features['login_frequency'] = len(user_events[user_events['event_type'] == 'login'])
        features['feature_usage_diversity'] = user_events['event_type'].nunique()
        features['avg_session_length'] = user_events['session_duration'].mean()
        features['error_rate'] = len(user_events[user_events['event_type'] == 'error']) / len(user_events)

        return features

    def predict_churn(self, user_id, features):
        """Predict if user will churn"""
        X = pd.DataFrame([features])
        churn_probability = self.model.predict_proba(X)[0][1]

        risk_level = 'low' if churn_probability < 0.3 else 'medium' if churn_probability < 0.7 else 'high'

        return {
            'user_id': user_id,
            'churn_probability': churn_probability,
            'risk_level': risk_level
        }

class RecommendationEngine:
    def __init__(self):
        self.user_item_matrix = None
        self.item_similarity = None

    def build_user_item_matrix(self, interactions):
        """Build user-item interaction matrix"""
        self.user_item_matrix = pd.pivot_table(
            interactions,
            values='rating',
            index='user_id',
            columns='item_id',
            fill_value=0
        )

    def calculate_similarity(self):
        """Calculate item similarity matrix"""
        from sklearn.metrics.pairwise import cosine_similarity
        self.item_similarity = cosine_similarity(self.user_item_matrix.T)

    def recommend(self, user_id, n_recommendations=10):
        """Generate recommendations for user"""
        if user_id not in self.user_item_matrix.index:
            return []

        user_ratings = self.user_item_matrix.loc[user_id]
        scores = self.item_similarity.dot(user_ratings) / np.abs(self.item_similarity).sum(axis=1)

        recommendations = pd.Series(scores, index=self.user_item_matrix.columns)
        recommendations = recommendations[user_ratings == 0]
        recommendations = recommendations.sort_values(ascending=False)

        return recommendations.head(n_recommendations).index.tolist()
