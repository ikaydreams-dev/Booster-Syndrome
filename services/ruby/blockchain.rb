require 'digest'
require 'json'
require 'time'

module Blockchain
  class Block
    attr_reader :index, :timestamp, :data, :previous_hash, :hash, :nonce

    def initialize(index, data, previous_hash)
      @index = index
      @timestamp = Time.now.to_i
      @data = data
      @previous_hash = previous_hash
      @nonce = 0
      @hash = calculate_hash
    end

    def calculate_hash
      Digest::SHA256.hexdigest(
        "#{@index}#{@timestamp}#{@data}#{@previous_hash}#{@nonce}"
      )
    end

    def mine(difficulty)
      target = '0' * difficulty

      until @hash.start_with?(target)
        @nonce += 1
        @hash = calculate_hash
      end

      @hash
    end

    def valid?
      @hash == calculate_hash
    end

    def to_h
      {
        index: @index,
        timestamp: @timestamp,
        data: @data,
        previous_hash: @previous_hash,
        hash: @hash,
        nonce: @nonce
      }
    end
  end

  class Chain
    attr_reader :chain, :difficulty

    def initialize(difficulty: 4)
      @chain = [create_genesis_block]
      @difficulty = difficulty
      @pending_transactions = []
      @mining_reward = 100
    end

    def create_genesis_block
      Block.new(0, 'Genesis Block', '0')
    end

    def get_latest_block
      @chain.last
    end

    def add_block(data)
      block = Block.new(
        @chain.length,
        data,
        get_latest_block.hash
      )

      block.mine(@difficulty)
      @chain << block
      block
    end

    def add_transaction(transaction)
      @pending_transactions << transaction
    end

    def mine_pending_transactions(miner_address)
      block = Block.new(
        @chain.length,
        @pending_transactions,
        get_latest_block.hash
      )

      block.mine(@difficulty)
      @chain << block

      @pending_transactions = [
        { from: 'system', to: miner_address, amount: @mining_reward }
      ]

      block
    end

    def get_balance(address)
      balance = 0

      @chain.each do |block|
        next if block.data == 'Genesis Block'

        transactions = block.data.is_a?(Array) ? block.data : [block.data]

        transactions.each do |tx|
          balance -= tx[:amount] if tx[:from] == address
          balance += tx[:amount] if tx[:to] == address
        end
      end

      balance
    end

    def valid?
      (1...@chain.length).each do |i|
        current_block = @chain[i]
        previous_block = @chain[i - 1]

        return false unless current_block.valid?
        return false if current_block.previous_hash != previous_block.hash
      end

      true
    end

    def to_json
      @chain.map(&:to_h).to_json
    end
  end

  class Wallet
    attr_reader :address, :private_key, :public_key

    def initialize
      @private_key = SecureRandom.hex(32)
      @public_key = Digest::SHA256.hexdigest(@private_key)
      @address = Digest::SHA256.hexdigest(@public_key)[0..39]
    end

    def sign_transaction(transaction)
      data = transaction.to_json
      Digest::SHA256.hexdigest(@private_key + data)
    end

    def to_h
      {
        address: @address,
        public_key: @public_key
      }
    end
  end

  class Transaction
    attr_reader :from, :to, :amount, :timestamp, :signature

    def initialize(from, to, amount)
      @from = from
      @to = to
      @amount = amount
      @timestamp = Time.now.to_i
      @signature = nil
    end

    def sign(private_key)
      data = "#{@from}#{@to}#{@amount}#{@timestamp}"
      @signature = Digest::SHA256.hexdigest(private_key + data)
    end

    def valid?
      return false if @from.nil? || @to.nil? || @amount <= 0
      return true if @from == 'system'
      !@signature.nil?
    end

    def to_h
      {
        from: @from,
        to: @to,
        amount: @amount,
        timestamp: @timestamp,
        signature: @signature
      }
    end

    def to_json
      to_h.to_json
    end
  end

  class MerkleTree
    attr_reader :root

    def initialize(transactions)
      @transactions = transactions
      @root = build_tree(transactions)
    end

    def build_tree(data)
      return nil if data.empty?
      return hash_data(data.first) if data.size == 1

      nodes = data.map { |item| hash_data(item) }

      while nodes.size > 1
        new_nodes = []

        nodes.each_slice(2) do |left, right|
          right ||= left
          new_nodes << hash_pair(left, right)
        end

        nodes = new_nodes
      end

      nodes.first
    end

    def verify(transaction, proof)
      current = hash_data(transaction)

      proof.each do |node|
        current = if node[:position] == 'left'
          hash_pair(node[:hash], current)
        else
          hash_pair(current, node[:hash])
        end
      end

      current == @root
    end

    private

    def hash_data(data)
      Digest::SHA256.hexdigest(data.to_json)
    end

    def hash_pair(left, right)
      Digest::SHA256.hexdigest(left + right)
    end
  end

  class SmartContract
    attr_reader :address, :code, :state

    def initialize(code)
      @address = Digest::SHA256.hexdigest(SecureRandom.hex(32))[0..39]
      @code = code
      @state = {}
    end

    def execute(method, *args)
      return nil unless @code.respond_to?(method)
      @code.send(method, @state, *args)
    end

    def get_state(key)
      @state[key]
    end

    def to_h
      {
        address: @address,
        state: @state
      }
    end
  end
end
