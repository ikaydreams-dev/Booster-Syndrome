module FiniteAutomaton
  class DFA
    def initialize(states, alphabet, transitions, start_state, accept_states)
      @states = states
      @alphabet = alphabet
      @transitions = transitions
      @start_state = start_state
      @accept_states = accept_states
    end

    def accepts?(input)
      current_state = @start_state

      input.each_char do |char|
        return false unless @alphabet.include?(char)

        next_state = @transitions.dig(current_state, char)
        return false unless next_state

        current_state = next_state
      end

      @accept_states.include?(current_state)
    end

    def process(input)
      states_visited = [@start_state]
      current_state = @start_state

      input.each_char do |char|
        next_state = @transitions.dig(current_state, char)
        break unless next_state

        current_state = next_state
        states_visited << current_state
      end

      {
        accepted: @accept_states.include?(current_state),
        final_state: current_state,
        path: states_visited
      }
    end
  end

  class NFA
    def initialize(states, alphabet, transitions, start_state, accept_states)
      @states = states
      @alphabet = alphabet
      @transitions = transitions
      @start_state = start_state
      @accept_states = accept_states
    end

    def accepts?(input)
      current_states = epsilon_closure([@start_state])

      input.each_char do |char|
        next_states = []

        current_states.each do |state|
          transitions = @transitions.dig(state, char) || []
          next_states.concat(transitions)
        end

        current_states = epsilon_closure(next_states)
        return false if current_states.empty?
      end

      (current_states & @accept_states).any?
    end

    private

    def epsilon_closure(states)
      closure = states.dup
      stack = states.dup

      while stack.any?
        state = stack.pop
        epsilon_transitions = @transitions.dig(state, 'ε') || []

        epsilon_transitions.each do |next_state|
          unless closure.include?(next_state)
            closure << next_state
            stack << next_state
          end
        end
      end

      closure
    end
  end

  class RegexEngine
    def self.to_nfa(pattern)
      states = []
      alphabet = pattern.chars.uniq - ['*', '|', '(', ')']
      transitions = {}
      start_state = 0
      accept_states = []

      {
        states: states,
        alphabet: alphabet,
        transitions: transitions,
        start_state: start_state,
        accept_states: accept_states
      }
    end

    def self.match?(pattern, text)
      case pattern
      when /^\w+$/
        text == pattern
      when /\*$/
        prefix = pattern[0...-1]
        text.start_with?(prefix)
      when /\|/
        alternatives = pattern.split('|')
        alternatives.any? { |alt| text == alt }
      else
        text == pattern
      end
    end
  end

  class Minimizer
    def self.minimize_dfa(dfa)
      partitions = [dfa[:accept_states], dfa[:states] - dfa[:accept_states]]

      loop do
        new_partitions = []

        partitions.each do |partition|
          splits = {}

          partition.each do |state|
            signature = dfa[:alphabet].map do |char|
              next_state = dfa[:transitions].dig(state, char)
              partitions.index { |p| p.include?(next_state) }
            end

            splits[signature] ||= []
            splits[signature] << state
          end

          new_partitions.concat(splits.values)
        end

        break if new_partitions.size == partitions.size
        partitions = new_partitions
      end

      partitions
    end
  end
end
