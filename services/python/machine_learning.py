import numpy as np
from typing import List, Tuple, Callable, Optional
from dataclasses import dataclass
import random

class LinearRegression:
    def __init__(self, learning_rate: float = 0.01, iterations: int = 1000):
        self.learning_rate = learning_rate
        self.iterations = iterations
        self.weights = None
        self.bias = None

    def fit(self, X: np.ndarray, y: np.ndarray):
        n_samples, n_features = X.shape
        self.weights = np.zeros(n_features)
        self.bias = 0

        for _ in range(self.iterations):
            y_pred = np.dot(X, self.weights) + self.bias

            dw = (1 / n_samples) * np.dot(X.T, (y_pred - y))
            db = (1 / n_samples) * np.sum(y_pred - y)

            self.weights -= self.learning_rate * dw
            self.bias -= self.learning_rate * db

    def predict(self, X: np.ndarray) -> np.ndarray:
        return np.dot(X, self.weights) + self.bias

class LogisticRegression:
    def __init__(self, learning_rate: float = 0.01, iterations: int = 1000):
        self.learning_rate = learning_rate
        self.iterations = iterations
        self.weights = None
        self.bias = None

    def _sigmoid(self, z: np.ndarray) -> np.ndarray:
        return 1 / (1 + np.exp(-z))

    def fit(self, X: np.ndarray, y: np.ndarray):
        n_samples, n_features = X.shape
        self.weights = np.zeros(n_features)
        self.bias = 0

        for _ in range(self.iterations):
            linear_pred = np.dot(X, self.weights) + self.bias
            y_pred = self._sigmoid(linear_pred)

            dw = (1 / n_samples) * np.dot(X.T, (y_pred - y))
            db = (1 / n_samples) * np.sum(y_pred - y)

            self.weights -= self.learning_rate * dw
            self.bias -= self.learning_rate * db

    def predict(self, X: np.ndarray) -> np.ndarray:
        linear_pred = np.dot(X, self.weights) + self.bias
        y_pred = self._sigmoid(linear_pred)
        return (y_pred >= 0.5).astype(int)

class KMeans:
    def __init__(self, k: int = 3, max_iters: int = 100):
        self.k = k
        self.max_iters = max_iters
        self.centroids = None
        self.labels = None

    def fit(self, X: np.ndarray):
        n_samples, n_features = X.shape

        random_indices = np.random.choice(n_samples, self.k, replace=False)
        self.centroids = X[random_indices]

        for _ in range(self.max_iters):
            distances = np.sqrt(((X - self.centroids[:, np.newaxis])**2).sum(axis=2))
            self.labels = np.argmin(distances, axis=0)

            new_centroids = np.array([X[self.labels == i].mean(axis=0) for i in range(self.k)])

            if np.allclose(self.centroids, new_centroids):
                break

            self.centroids = new_centroids

    def predict(self, X: np.ndarray) -> np.ndarray:
        distances = np.sqrt(((X - self.centroids[:, np.newaxis])**2).sum(axis=2))
        return np.argmin(distances, axis=0)

class DecisionTree:
    def __init__(self, max_depth: int = 10, min_samples_split: int = 2):
        self.max_depth = max_depth
        self.min_samples_split = min_samples_split
        self.root = None

    class Node:
        def __init__(self, feature=None, threshold=None, left=None, right=None, value=None):
            self.feature = feature
            self.threshold = threshold
            self.left = left
            self.right = right
            self.value = value

        def is_leaf(self):
            return self.value is not None

    def _gini(self, y: np.ndarray) -> float:
        proportions = np.bincount(y) / len(y)
        return 1 - np.sum(proportions ** 2)

    def _split(self, X: np.ndarray, y: np.ndarray, feature: int, threshold: float) -> Tuple:
        left_mask = X[:, feature] <= threshold
        right_mask = ~left_mask
        return X[left_mask], X[right_mask], y[left_mask], y[right_mask]

    def _best_split(self, X: np.ndarray, y: np.ndarray) -> Tuple:
        best_gini = float('inf')
        best_feature = None
        best_threshold = None

        n_features = X.shape[1]

        for feature in range(n_features):
            thresholds = np.unique(X[:, feature])

            for threshold in thresholds:
                X_left, X_right, y_left, y_right = self._split(X, y, feature, threshold)

                if len(y_left) == 0 or len(y_right) == 0:
                    continue

                gini = (len(y_left) / len(y)) * self._gini(y_left) + \
                       (len(y_right) / len(y)) * self._gini(y_right)

                if gini < best_gini:
                    best_gini = gini
                    best_feature = feature
                    best_threshold = threshold

        return best_feature, best_threshold

    def _build_tree(self, X: np.ndarray, y: np.ndarray, depth: int = 0):
        n_samples, n_features = X.shape
        n_classes = len(np.unique(y))

        if depth >= self.max_depth or n_samples < self.min_samples_split or n_classes == 1:
            leaf_value = np.bincount(y).argmax()
            return self.Node(value=leaf_value)

        feature, threshold = self._best_split(X, y)

        if feature is None:
            leaf_value = np.bincount(y).argmax()
            return self.Node(value=leaf_value)

        X_left, X_right, y_left, y_right = self._split(X, y, feature, threshold)

        left = self._build_tree(X_left, y_left, depth + 1)
        right = self._build_tree(X_right, y_right, depth + 1)

        return self.Node(feature=feature, threshold=threshold, left=left, right=right)

    def fit(self, X: np.ndarray, y: np.ndarray):
        self.root = self._build_tree(X, y)

    def _predict_sample(self, x: np.ndarray, node):
        if node.is_leaf():
            return node.value

        if x[node.feature] <= node.threshold:
            return self._predict_sample(x, node.left)
        else:
            return self._predict_sample(x, node.right)

    def predict(self, X: np.ndarray) -> np.ndarray:
        return np.array([self._predict_sample(x, self.root) for x in X])

class NeuralNetwork:
    def __init__(self, layers: List[int], learning_rate: float = 0.01):
        self.layers = layers
        self.learning_rate = learning_rate
        self.weights = []
        self.biases = []

        for i in range(len(layers) - 1):
            w = np.random.randn(layers[i], layers[i + 1]) * 0.01
            b = np.zeros((1, layers[i + 1]))
            self.weights.append(w)
            self.biases.append(b)

    def _sigmoid(self, z: np.ndarray) -> np.ndarray:
        return 1 / (1 + np.exp(-np.clip(z, -500, 500)))

    def _sigmoid_derivative(self, z: np.ndarray) -> np.ndarray:
        s = self._sigmoid(z)
        return s * (1 - s)

    def _forward(self, X: np.ndarray) -> Tuple:
        activations = [X]
        zs = []

        for w, b in zip(self.weights, self.biases):
            z = np.dot(activations[-1], w) + b
            zs.append(z)
            a = self._sigmoid(z)
            activations.append(a)

        return activations, zs

    def _backward(self, X: np.ndarray, y: np.ndarray, activations: List, zs: List):
        m = X.shape[0]
        deltas = [None] * len(self.weights)

        deltas[-1] = activations[-1] - y

        for i in range(len(deltas) - 2, -1, -1):
            deltas[i] = np.dot(deltas[i + 1], self.weights[i + 1].T) * \
                        self._sigmoid_derivative(zs[i])

        for i in range(len(self.weights)):
            self.weights[i] -= self.learning_rate * np.dot(activations[i].T, deltas[i]) / m
            self.biases[i] -= self.learning_rate * np.sum(deltas[i], axis=0, keepdims=True) / m

    def fit(self, X: np.ndarray, y: np.ndarray, epochs: int = 1000):
        for _ in range(epochs):
            activations, zs = self._forward(X)
            self._backward(X, y, activations, zs)

    def predict(self, X: np.ndarray) -> np.ndarray:
        activations, _ = self._forward(X)
        return activations[-1]

class PCA:
    def __init__(self, n_components: int):
        self.n_components = n_components
        self.components = None
        self.mean = None

    def fit(self, X: np.ndarray):
        self.mean = np.mean(X, axis=0)
        X_centered = X - self.mean

        cov_matrix = np.cov(X_centered.T)
        eigenvalues, eigenvectors = np.linalg.eig(cov_matrix)

        indices = np.argsort(eigenvalues)[::-1]
        eigenvectors = eigenvectors[:, indices]

        self.components = eigenvectors[:, :self.n_components]

    def transform(self, X: np.ndarray) -> np.ndarray:
        X_centered = X - self.mean
        return np.dot(X_centered, self.components)

    def fit_transform(self, X: np.ndarray) -> np.ndarray:
        self.fit(X)
        return self.transform(X)

class SVM:
    def __init__(self, learning_rate: float = 0.001, lambda_param: float = 0.01, iterations: int = 1000):
        self.learning_rate = learning_rate
        self.lambda_param = lambda_param
        self.iterations = iterations
        self.weights = None
        self.bias = None

    def fit(self, X: np.ndarray, y: np.ndarray):
        n_samples, n_features = X.shape
        y_ = np.where(y <= 0, -1, 1)

        self.weights = np.zeros(n_features)
        self.bias = 0

        for _ in range(self.iterations):
            for idx, x_i in enumerate(X):
                condition = y_[idx] * (np.dot(x_i, self.weights) - self.bias) >= 1

                if condition:
                    self.weights -= self.learning_rate * (2 * self.lambda_param * self.weights)
                else:
                    self.weights -= self.learning_rate * (
                        2 * self.lambda_param * self.weights - np.dot(x_i, y_[idx])
                    )
                    self.bias -= self.learning_rate * y_[idx]

    def predict(self, X: np.ndarray) -> np.ndarray:
        approx = np.dot(X, self.weights) - self.bias
        return np.sign(approx)

class RandomForest:
    def __init__(self, n_trees: int = 10, max_depth: int = 10, min_samples_split: int = 2):
        self.n_trees = n_trees
        self.max_depth = max_depth
        self.min_samples_split = min_samples_split
        self.trees = []

    def _bootstrap_sample(self, X: np.ndarray, y: np.ndarray) -> Tuple:
        n_samples = X.shape[0]
        indices = np.random.choice(n_samples, n_samples, replace=True)
        return X[indices], y[indices]

    def fit(self, X: np.ndarray, y: np.ndarray):
        self.trees = []

        for _ in range(self.n_trees):
            tree = DecisionTree(max_depth=self.max_depth, min_samples_split=self.min_samples_split)
            X_sample, y_sample = self._bootstrap_sample(X, y)
            tree.fit(X_sample, y_sample)
            self.trees.append(tree)

    def predict(self, X: np.ndarray) -> np.ndarray:
        predictions = np.array([tree.predict(X) for tree in self.trees])
        return np.array([np.bincount(predictions[:, i]).argmax() for i in range(X.shape[0])])

class GradientBoosting:
    def __init__(self, n_estimators: int = 100, learning_rate: float = 0.1, max_depth: int = 3):
        self.n_estimators = n_estimators
        self.learning_rate = learning_rate
        self.max_depth = max_depth
        self.trees = []

    def fit(self, X: np.ndarray, y: np.ndarray):
        self.trees = []
        predictions = np.zeros(len(y))

        for _ in range(self.n_estimators):
            residuals = y - predictions

            tree = DecisionTree(max_depth=self.max_depth)
            tree.fit(X, residuals)

            update = tree.predict(X)
            predictions += self.learning_rate * update

            self.trees.append(tree)

    def predict(self, X: np.ndarray) -> np.ndarray:
        predictions = np.zeros(len(X))

        for tree in self.trees:
            predictions += self.learning_rate * tree.predict(X)

        return predictions
