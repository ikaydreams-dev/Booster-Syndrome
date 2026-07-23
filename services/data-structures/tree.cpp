#include <iostream>
#include <queue>
#include <vector>

template<typename T>
class TreeNode {
public:
    T data;
    TreeNode* left;
    TreeNode* right;

    TreeNode(T value) : data(value), left(nullptr), right(nullptr) {}
};

template<typename T>
class BinarySearchTree {
private:
    TreeNode<T>* root;

    TreeNode<T>* insertHelper(TreeNode<T>* node, T value) {
        if (node == nullptr) {
            return new TreeNode<T>(value);
        }

        if (value < node->data) {
            node->left = insertHelper(node->left, value);
        } else if (value > node->data) {
            node->right = insertHelper(node->right, value);
        }

        return node;
    }

    TreeNode<T>* findMin(TreeNode<T>* node) {
        while (node->left != nullptr) {
            node = node->left;
        }
        return node;
    }

    TreeNode<T>* removeHelper(TreeNode<T>* node, T value) {
        if (node == nullptr) return nullptr;

        if (value < node->data) {
            node->left = removeHelper(node->left, value);
        } else if (value > node->data) {
            node->right = removeHelper(node->right, value);
        } else {
            if (node->left == nullptr && node->right == nullptr) {
                delete node;
                return nullptr;
            } else if (node->left == nullptr) {
                TreeNode<T>* temp = node->right;
                delete node;
                return temp;
            } else if (node->right == nullptr) {
                TreeNode<T>* temp = node->left;
                delete node;
                return temp;
            } else {
                TreeNode<T>* temp = findMin(node->right);
                node->data = temp->data;
                node->right = removeHelper(node->right, temp->data);
            }
        }

        return node;
    }

    bool searchHelper(TreeNode<T>* node, T value) {
        if (node == nullptr) return false;
        if (node->data == value) return true;

        if (value < node->data) {
            return searchHelper(node->left, value);
        } else {
            return searchHelper(node->right, value);
        }
    }

    void inorderHelper(TreeNode<T>* node, std::vector<T>& result) {
        if (node != nullptr) {
            inorderHelper(node->left, result);
            result.push_back(node->data);
            inorderHelper(node->right, result);
        }
    }

public:
    BinarySearchTree() : root(nullptr) {}

    void insert(T value) {
        root = insertHelper(root, value);
    }

    void remove(T value) {
        root = removeHelper(root, value);
    }

    bool search(T value) {
        return searchHelper(root, value);
    }

    std::vector<T> inorderTraversal() {
        std::vector<T> result;
        inorderHelper(root, result);
        return result;
    }

    std::vector<T> levelOrderTraversal() {
        std::vector<T> result;
        if (root == nullptr) return result;

        std::queue<TreeNode<T>*> q;
        q.push(root);

        while (!q.empty()) {
            TreeNode<T>* current = q.front();
            q.pop();
            result.push_back(current->data);

            if (current->left != nullptr) q.push(current->left);
            if (current->right != nullptr) q.push(current->right);
        }

        return result;
    }
};
