module StateMachine
  class State
    attr_reader :name, :on_enter, :on_exit

    def initialize(name, on_enter: nil, on_exit: nil)
      @name = name
      @on_enter = on_enter
      @on_exit = on_exit
    end

    def enter(context = nil)
      @on_enter&.call(context)
    end

    def exit(context = nil)
      @on_exit&.call(context)
    end
  end

  class Transition
    attr_reader :from, :to, :event, :guard, :action

    def initialize(from:, to:, event:, guard: nil, action: nil)
      @from = from
      @to = to
      @event = event
      @guard = guard
      @action = action
    end

    def can_execute?(context = nil)
      return true unless @guard
      @guard.call(context)
    end

    def execute(context = nil)
      @action&.call(context)
    end
  end

  class Machine
    attr_reader :current_state, :states, :transitions

    def initialize(initial_state)
      @states = {}
      @transitions = []
      @current_state = initial_state
      @context = {}
    end

    def add_state(name, on_enter: nil, on_exit: nil)
      @states[name] = State.new(name, on_enter: on_enter, on_exit: on_exit)
    end

    def add_transition(from:, to:, event:, guard: nil, action: nil)
      transition = Transition.new(
        from: from,
        to: to,
        event: event,
        guard: guard,
        action: action
      )
      @transitions << transition
    end

    def trigger(event, context = nil)
      transition = find_transition(event)

      unless transition
        raise "No transition found for event '#{event}' from state '#{@current_state}'"
      end

      unless transition.can_execute?(context)
        raise "Guard condition failed for transition from '#{@current_state}' to '#{transition.to}'"
      end

      current_state_obj = @states[@current_state]
      next_state_obj = @states[transition.to]

      current_state_obj&.exit(context)
      transition.execute(context)

      @current_state = transition.to
      next_state_obj&.enter(context)

      @current_state
    end

    def can_trigger?(event, context = nil)
      transition = find_transition(event)
      return false unless transition

      transition.can_execute?(context)
    end

    def available_events
      @transitions
        .select { |t| t.from == @current_state }
        .map(&:event)
        .uniq
    end

    def in_state?(state)
      @current_state == state
    end

    def reset(initial_state = nil)
      @current_state = initial_state || @states.keys.first
    end

    private

    def find_transition(event)
      @transitions.find do |t|
        t.from == @current_state && t.event == event
      end
    end
  end

  class Builder
    def initialize
      @states = []
      @transitions = []
      @initial_state = nil
    end

    def initial(state)
      @initial_state = state
      self
    end

    def state(name, on_enter: nil, on_exit: nil)
      @states << { name: name, on_enter: on_enter, on_exit: on_exit }
      self
    end

    def transition(from:, to:, event:, guard: nil, action: nil)
      @transitions << {
        from: from,
        to: to,
        event: event,
        guard: guard,
        action: action
      }
      self
    end

    def build
      raise 'Initial state not set' unless @initial_state

      machine = Machine.new(@initial_state)

      @states.each do |state|
        machine.add_state(state[:name], on_enter: state[:on_enter], on_exit: state[:on_exit])
      end

      @transitions.each do |transition|
        machine.add_transition(**transition)
      end

      machine
    end
  end

  class History
    def initialize
      @history = []
      @max_size = 100
    end

    def record(from:, to:, event:, timestamp: Time.now)
      @history << {
        from: from,
        to: to,
        event: event,
        timestamp: timestamp
      }

      @history.shift if @history.size > @max_size
    end

    def last(n = 10)
      @history.last(n)
    end

    def all
      @history.dup
    end

    def clear
      @history.clear
    end

    def transitions_to(state)
      @history.select { |entry| entry[:to] == state }
    end

    def transitions_from(state)
      @history.select { |entry| entry[:from] == state }
    end
  end

  class StatefulMachine < Machine
    def initialize(initial_state)
      super
      @history = History.new
    end

    def trigger(event, context = nil)
      from_state = @current_state
      result = super

      @history.record(
        from: from_state,
        to: @current_state,
        event: event
      )

      result
    end

    def history
      @history
    end

    def can_rollback?
      @history.all.any?
    end

    def rollback
      last_transition = @history.all.last
      return false unless last_transition

      @current_state = last_transition[:from]
      @history.all.pop

      true
    end
  end
end
