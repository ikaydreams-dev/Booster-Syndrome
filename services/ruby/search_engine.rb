module Search
  class Document
    attr_reader :id, :content, :metadata

    def initialize(id, content, metadata: {})
      @id = id
      @content = content
      @metadata = metadata
    end

    def tokens
      tokenize(@content)
    end

    private

    def tokenize(text)
      text.downcase.scan(/\w+/)
    end
  end

  class InvertedIndex
    def initialize
      @index = Hash.new { |h, k| h[k] = Set.new }
      @documents = {}
      @idf_cache = {}
    end

    def add_document(document)
      @documents[document.id] = document
      @idf_cache.clear

      document.tokens.each do |token|
        @index[token] << document.id
      end
    end

    def remove_document(document_id)
      doc = @documents.delete(document_id)
      return unless doc

      @idf_cache.clear

      doc.tokens.each do |token|
        @index[token].delete(document_id)
      end
    end

    def search(query, limit: 10)
      query_tokens = tokenize(query)
      return [] if query_tokens.empty?

      scores = calculate_scores(query_tokens)

      scores.sort_by { |_, score| -score }
            .take(limit)
            .map { |doc_id, score| { document_id: doc_id, score: score } }
    end

    def autocomplete(prefix, limit: 10)
      matches = @index.keys.select { |term| term.start_with?(prefix.downcase) }
      matches.take(limit)
    end

    def document_count
      @documents.size
    end

    def term_count
      @index.size
    end

    private

    def tokenize(text)
      text.downcase.scan(/\w+/)
    end

    def calculate_scores(query_tokens)
      scores = Hash.new(0)

      query_tokens.each do |token|
        doc_ids = @index[token]
        idf = calculate_idf(token)

        doc_ids.each do |doc_id|
          tf = calculate_tf(doc_id, token)
          scores[doc_id] += tf * idf
        end
      end

      scores
    end

    def calculate_tf(doc_id, term)
      doc = @documents[doc_id]
      return 0 unless doc

      term_count = doc.tokens.count(term)
      total_terms = doc.tokens.size

      term_count / total_terms.to_f
    end

    def calculate_idf(term)
      return @idf_cache[term] if @idf_cache.key?(term)

      doc_count = @index[term].size
      idf = doc_count > 0 ? Math.log(@documents.size / doc_count.to_f) : 0

      @idf_cache[term] = idf
      idf
    end
  end

  class FullTextSearch
    def initialize
      @index = InvertedIndex.new
      @filters = []
    end

    def index_document(id, content, metadata: {})
      doc = Document.new(id, content, metadata: metadata)
      @index.add_document(doc)
    end

    def search(query, filters: {}, limit: 10)
      results = @index.search(query, limit: limit * 2)

      if filters.any?
        results = results.select do |result|
          doc = get_document(result[:document_id])
          matches_filters?(doc, filters)
        end
      end

      results.take(limit)
    end

    def faceted_search(query, facets: [])
      results = @index.search(query, limit: 1000)

      facet_counts = {}

      facets.each do |facet|
        facet_counts[facet] = Hash.new(0)

        results.each do |result|
          doc = get_document(result[:document_id])
          value = doc.metadata[facet]
          facet_counts[facet][value] += 1 if value
        end
      end

      {
        results: results.take(10),
        facets: facet_counts
      }
    end

    def suggest(partial_query, limit: 5)
      @index.autocomplete(partial_query, limit: limit)
    end

    def similar_documents(document_id, limit: 10)
      doc = get_document(document_id)
      return [] unless doc

      @index.search(doc.content, limit: limit + 1)
            .reject { |r| r[:document_id] == document_id }
            .take(limit)
    end

    private

    def get_document(doc_id)
      @index.instance_variable_get(:@documents)[doc_id]
    end

    def matches_filters?(doc, filters)
      filters.all? do |key, value|
        doc.metadata[key] == value
      end
    end
  end

  class FuzzyMatcher
    def self.levenshtein_distance(str1, str2)
      matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

      (0..str1.length).each { |i| matrix[i][0] = i }
      (0..str2.length).each { |j| matrix[0][j] = j }

      (1..str1.length).each do |i|
        (1..str2.length).each do |j|
          cost = str1[i - 1] == str2[j - 1] ? 0 : 1

          matrix[i][j] = [
            matrix[i - 1][j] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j - 1] + cost
          ].min
        end
      end

      matrix[str1.length][str2.length]
    end

    def self.similarity(str1, str2)
      distance = levenshtein_distance(str1, str2)
      max_length = [str1.length, str2.length].max

      return 1.0 if max_length == 0

      1.0 - (distance / max_length.to_f)
    end

    def self.fuzzy_match(query, candidates, threshold: 0.6)
      matches = candidates.map do |candidate|
        similarity = similarity(query.downcase, candidate.downcase)
        { value: candidate, similarity: similarity }
      end

      matches.select { |m| m[:similarity] >= threshold }
             .sort_by { |m| -m[:similarity] }
    end
  end

  class Ranker
    def self.bm25(query_terms, doc_terms, avg_doc_length, total_docs, doc_frequency)
      k1 = 1.5
      b = 0.75

      score = 0

      query_terms.each do |term|
        tf = doc_terms.count(term)
        df = doc_frequency[term] || 1
        idf = Math.log((total_docs - df + 0.5) / (df + 0.5))

        numerator = tf * (k1 + 1)
        denominator = tf + k1 * (1 - b + b * (doc_terms.length / avg_doc_length.to_f))

        score += idf * (numerator / denominator)
      end

      score
    end
  end

  class QueryParser
    def self.parse(query)
      tokens = tokenize(query)

      {
        required: extract_required(tokens),
        excluded: extract_excluded(tokens),
        optional: extract_optional(tokens),
        phrase: extract_phrases(query)
      }
    end

    private

    def self.tokenize(text)
      text.scan(/[+\-]?"[^"]+"|[+\-]?\w+/)
    end

    def self.extract_required(tokens)
      tokens.select { |t| t.start_with?('+') }
            .map { |t| t[1..-1].tr('"', '') }
    end

    def self.extract_excluded(tokens)
      tokens.select { |t| t.start_with?('-') }
            .map { |t| t[1..-1].tr('"', '') }
    end

    def self.extract_optional(tokens)
      tokens.reject { |t| t.start_with?('+', '-') }
            .map { |t| t.tr('"', '') }
    end

    def self.extract_phrases(query)
      query.scan(/"([^"]+)"/).flatten
    end
  end
end
