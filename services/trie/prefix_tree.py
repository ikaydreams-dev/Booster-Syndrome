class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end_of_word = False
        self.value = None

class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word: str, value=None):
        """Insert word into trie"""
        node = self.root

        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]

        node.is_end_of_word = True
        node.value = value

    def search(self, word: str) -> bool:
        """Search for exact word"""
        node = self._find_node(word)
        return node is not None and node.is_end_of_word

    def starts_with(self, prefix: str) -> bool:
        """Check if any word starts with prefix"""
        return self._find_node(prefix) is not None

    def _find_node(self, prefix: str):
        """Find node for given prefix"""
        node = self.root

        for char in prefix:
            if char not in node.children:
                return None
            node = node.children[char]

        return node

    def get(self, word: str):
        """Get value associated with word"""
        node = self._find_node(word)

        if node and node.is_end_of_word:
            return node.value

        return None

    def delete(self, word: str) -> bool:
        """Delete word from trie"""
        def _delete_helper(node, word, index):
            if index == len(word):
                if not node.is_end_of_word:
                    return False

                node.is_end_of_word = False
                node.value = None
                return len(node.children) == 0

            char = word[index]

            if char not in node.children:
                return False

            should_delete = _delete_helper(node.children[char], word, index + 1)

            if should_delete:
                del node.children[char]
                return len(node.children) == 0 and not node.is_end_of_word

            return False

        return _delete_helper(self.root, word, 0)

    def autocomplete(self, prefix: str, limit: int = 10) -> list:
        """Get words with given prefix"""
        node = self._find_node(prefix)

        if not node:
            return []

        results = []
        self._collect_words(node, prefix, results, limit)
        return results

    def _collect_words(self, node, current_word, results, limit):
        """Collect all words under node"""
        if len(results) >= limit:
            return

        if node.is_end_of_word:
            results.append(current_word)

        for char, child_node in node.children.items():
            self._collect_words(child_node, current_word + char, results, limit)

    def count_words(self) -> int:
        """Count total words in trie"""
        def _count(node):
            count = 1 if node.is_end_of_word else 0

            for child in node.children.values():
                count += _count(child)

            return count

        return _count(self.root)

trie = Trie()
