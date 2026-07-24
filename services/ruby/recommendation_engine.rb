module Recommendation
  class CollaborativeFiltering
    def initialize
      @ratings = Hash.new { |h, k| h[k] = {} }
      @similarity_cache = {}
    end

    def add_rating(user_id, item_id, rating)
      @ratings[user_id][item_id] = rating
      @similarity_cache.clear
    end

    def recommend(user_id, limit: 10)
      user_ratings = @ratings[user_id]
      return [] if user_ratings.empty?

      predictions = {}

      @ratings.each do |other_user_id, other_ratings|
        next if other_user_id == user_id

        similarity = calculate_similarity(user_id, other_user_id)
        next if similarity <= 0

        other_ratings.each do |item_id, rating|
          next if user_ratings.key?(item_id)

          predictions[item_id] ||= { sum: 0, weight_sum: 0 }
          predictions[item_id][:sum] += similarity * rating
          predictions[item_id][:weight_sum] += similarity
        end
      end

      recommendations = predictions.map do |item_id, data|
        score = data[:weight_sum] > 0 ? data[:sum] / data[:weight_sum] : 0
        { item_id: item_id, score: score }
      end

      recommendations.sort_by { |r| -r[:score] }.take(limit)
    end

    def similar_users(user_id, limit: 10)
      similarities = @ratings.keys.map do |other_user_id|
        next if other_user_id == user_id

        similarity = calculate_similarity(user_id, other_user_id)
        { user_id: other_user_id, similarity: similarity }
      end.compact

      similarities.sort_by { |s| -s[:similarity] }.take(limit)
    end

    private

    def calculate_similarity(user1, user2)
      cache_key = [user1, user2].sort.join(':')
      return @similarity_cache[cache_key] if @similarity_cache.key?(cache_key)

      ratings1 = @ratings[user1]
      ratings2 = @ratings[user2]

      common_items = ratings1.keys & ratings2.keys
      return 0 if common_items.empty?

      sum_squares1 = 0
      sum_squares2 = 0
      sum_products = 0

      common_items.each do |item_id|
        r1 = ratings1[item_id]
        r2 = ratings2[item_id]

        sum_squares1 += r1 * r1
        sum_squares2 += r2 * r2
        sum_products += r1 * r2
      end

      denominator = Math.sqrt(sum_squares1) * Math.sqrt(sum_squares2)
      similarity = denominator > 0 ? sum_products / denominator : 0

      @similarity_cache[cache_key] = similarity
      similarity
    end
  end

  class ContentBased
    def initialize
      @items = {}
      @user_profiles = Hash.new { |h, k| h[k] = {} }
    end

    def add_item(item_id, features)
      @items[item_id] = normalize_features(features)
    end

    def add_user_interaction(user_id, item_id, weight: 1.0)
      item_features = @items[item_id]
      return unless item_features

      item_features.each do |feature, value|
        @user_profiles[user_id][feature] ||= 0
        @user_profiles[user_id][feature] += value * weight
      end

      normalize_user_profile(user_id)
    end

    def recommend(user_id, limit: 10)
      profile = @user_profiles[user_id]
      return [] if profile.empty?

      scores = @items.map do |item_id, features|
        next if interacted?(user_id, item_id)

        score = calculate_similarity(profile, features)
        { item_id: item_id, score: score }
      end.compact

      scores.sort_by { |s| -s[:score] }.take(limit)
    end

    private

    def normalize_features(features)
      magnitude = Math.sqrt(features.values.map { |v| v * v }.sum)
      return features if magnitude == 0

      features.transform_values { |v| v / magnitude }
    end

    def normalize_user_profile(user_id)
      @user_profiles[user_id] = normalize_features(@user_profiles[user_id])
    end

    def calculate_similarity(profile1, profile2)
      common_features = profile1.keys & profile2.keys
      return 0 if common_features.empty?

      common_features.sum { |feature| profile1[feature] * profile2[feature] }
    end

    def interacted?(user_id, item_id)
      false
    end
  end

  class HybridRecommender
    def initialize
      @collaborative = CollaborativeFiltering.new
      @content_based = ContentBased.new
      @collaborative_weight = 0.5
      @content_weight = 0.5
    end

    def set_weights(collaborative:, content:)
      total = collaborative + content
      @collaborative_weight = collaborative / total.to_f
      @content_weight = content / total.to_f
    end

    def add_rating(user_id, item_id, rating)
      @collaborative.add_rating(user_id, item_id, rating)
    end

    def add_item(item_id, features)
      @content_based.add_item(item_id, features)
    end

    def add_interaction(user_id, item_id, weight: 1.0)
      @content_based.add_user_interaction(user_id, item_id, weight: weight)
    end

    def recommend(user_id, limit: 10)
      collab_recs = @collaborative.recommend(user_id, limit: limit * 2)
      content_recs = @content_based.recommend(user_id, limit: limit * 2)

      combined = {}

      collab_recs.each do |rec|
        combined[rec[:item_id]] = rec[:score] * @collaborative_weight
      end

      content_recs.each do |rec|
        combined[rec[:item_id]] ||= 0
        combined[rec[:item_id]] += rec[:score] * @content_weight
      end

      combined.map { |item_id, score| { item_id: item_id, score: score } }
              .sort_by { |r| -r[:score] }
              .take(limit)
    end
  end

  class TrendingItems
    def initialize(decay_factor: 0.9)
      @scores = Hash.new(0)
      @decay_factor = decay_factor
      @last_decay = Time.now
    end

    def record_view(item_id, weight: 1.0)
      apply_decay
      @scores[item_id] += weight
    end

    def trending(limit: 10)
      apply_decay

      @scores.map { |item_id, score| { item_id: item_id, score: score } }
             .sort_by { |item| -item[:score] }
             .take(limit)
    end

    private

    def apply_decay
      hours_passed = (Time.now - @last_decay) / 3600.0

      if hours_passed >= 1
        decay = @decay_factor ** hours_passed.floor
        @scores.transform_values! { |score| score * decay }
        @last_decay = Time.now
      end
    end
  end

  class AssociationRules
    def initialize(min_support: 0.01, min_confidence: 0.5)
      @min_support = min_support
      @min_confidence = min_confidence
      @transactions = []
      @rules = []
    end

    def add_transaction(items)
      @transactions << items.to_set
    end

    def mine_rules
      frequent_items = find_frequent_itemsets
      @rules = generate_rules(frequent_items)
    end

    def recommend(basket, limit: 10)
      basket_set = basket.to_set

      recommendations = @rules.select do |rule|
        rule[:antecedent].subset?(basket_set)
      end

      recommendations.map do |rule|
        consequent = rule[:consequent].to_a
        {
          items: consequent,
          confidence: rule[:confidence],
          lift: rule[:lift]
        }
      end.sort_by { |r| -r[:confidence] }.take(limit)
    end

    private

    def find_frequent_itemsets
      item_counts = Hash.new(0)

      @transactions.each do |transaction|
        transaction.each { |item| item_counts[item] += 1 }
      end

      min_count = @transactions.size * @min_support

      item_counts.select { |_, count| count >= min_count }.keys
    end

    def generate_rules(frequent_items)
      rules = []

      frequent_items.combination(2).each do |item1, item2|
        support_both = @transactions.count { |t| t.include?(item1) && t.include?(item2) }
        support_item1 = @transactions.count { |t| t.include?(item1) }

        next if support_item1 == 0

        confidence = support_both / support_item1.to_f

        next if confidence < @min_confidence

        rules << {
          antecedent: Set[item1],
          consequent: Set[item2],
          confidence: confidence,
          support: support_both / @transactions.size.to_f,
          lift: confidence / (@transactions.count { |t| t.include?(item2) } / @transactions.size.to_f)
        }
      end

      rules
    end
  end
end
