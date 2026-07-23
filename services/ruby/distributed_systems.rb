require 'socket'
require 'json'

module Distributed
  class Node
    attr_reader :id, :host, :port, :state

    def initialize(host: 'localhost', port: 8080)
      @id = SecureRandom.uuid
      @host = host
      @port = port
      @state = :follower
      @peers = []
      @data = {}
      @mutex = Mutex.new
    end

    def add_peer(host, port)
      @mutex.synchronize do
        @peers << { host: host, port: port }
      end
    end

    def set(key, value)
      @mutex.synchronize do
        @data[key] = value
      end

      replicate_to_peers(key, value)
    end

    def get(key)
      @mutex.synchronize do
        @data[key]
      end
    end

    def all_data
      @mutex.synchronize do
        @data.dup
      end
    end

    private

    def replicate_to_peers(key, value)
      @peers.each do |peer|
        Thread.new do
          begin
            socket = TCPSocket.new(peer[:host], peer[:port])
            message = { type: 'replicate', key: key, value: value }.to_json
            socket.puts(message)
            socket.close
          rescue => e
            puts "Failed to replicate to #{peer[:host]}:#{peer[:port]} - #{e.message}"
          end
        end
      end
    end
  end

  class ConsistentHash
    def initialize(replicas: 150)
      @replicas = replicas
      @ring = {}
      @sorted_keys = []
      @nodes = []
    end

    def add_node(node)
      @nodes << node

      @replicas.times do |i|
        key = hash_key("#{node}:#{i}")
        @ring[key] = node
      end

      @sorted_keys = @ring.keys.sort
    end

    def remove_node(node)
      @nodes.delete(node)

      @replicas.times do |i|
        key = hash_key("#{node}:#{i}")
        @ring.delete(key)
      end

      @sorted_keys = @ring.keys.sort
    end

    def get_node(key)
      return nil if @sorted_keys.empty?

      hash = hash_key(key)

      @sorted_keys.each do |ring_key|
        return @ring[ring_key] if ring_key >= hash
      end

      @ring[@sorted_keys.first]
    end

    def get_nodes(key, count)
      return [] if @sorted_keys.empty?

      nodes = []
      hash = hash_key(key)
      index = @sorted_keys.bsearch_index { |k| k >= hash } || 0

      count.times do |i|
        ring_key = @sorted_keys[(index + i) % @sorted_keys.size]
        node = @ring[ring_key]
        nodes << node unless nodes.include?(node)
      end

      nodes
    end

    private

    def hash_key(key)
      Digest::MD5.hexdigest(key.to_s).to_i(16)
    end
  end

  class Gossip
    def initialize(node_id)
      @node_id = node_id
      @peers = []
      @data = {}
      @versions = {}
      @mutex = Mutex.new
    end

    def add_peer(peer_id, connection)
      @mutex.synchronize do
        @peers << { id: peer_id, connection: connection }
      end
    end

    def set(key, value)
      @mutex.synchronize do
        @data[key] = value
        @versions[key] = (@versions[key] || 0) + 1
      end

      gossip_update(key, value, @versions[key])
    end

    def get(key)
      @mutex.synchronize do
        @data[key]
      end
    end

    def receive_update(key, value, version)
      @mutex.synchronize do
        current_version = @versions[key] || 0

        if version > current_version
          @data[key] = value
          @versions[key] = version
        end
      end
    end

    def gossip_round
      @mutex.synchronize do
        return if @peers.empty?

        peer = @peers.sample

        @data.each do |key, value|
          version = @versions[key]
          peer[:connection].send_update(key, value, version)
        end
      end
    end

    private

    def gossip_update(key, value, version)
      @peers.each do |peer|
        Thread.new do
          begin
            peer[:connection].send_update(key, value, version)
          rescue => e
            puts "Failed to gossip to peer #{peer[:id]}: #{e.message}"
          end
        end
      end
    end
  end

  class VectorClock
    def initialize(node_id)
      @node_id = node_id
      @clock = Hash.new(0)
      @mutex = Mutex.new
    end

    def increment
      @mutex.synchronize do
        @clock[@node_id] += 1
        @clock.dup
      end
    end

    def update(other_clock)
      @mutex.synchronize do
        other_clock.each do |node, timestamp|
          @clock[node] = [@clock[node], timestamp].max
        end
        @clock[@node_id] += 1
      end
    end

    def happens_before?(other_clock)
      @mutex.synchronize do
        all_less_or_equal = @clock.all? do |node, timestamp|
          timestamp <= (other_clock[node] || 0)
        end

        any_less = @clock.any? do |node, timestamp|
          timestamp < (other_clock[node] || 0)
        end

        all_less_or_equal && any_less
      end
    end

    def concurrent?(other_clock)
      !happens_before?(other_clock) && !happens_after?(other_clock)
    end

    def happens_after?(other_clock)
      @mutex.synchronize do
        all_greater_or_equal = @clock.all? do |node, timestamp|
          timestamp >= (other_clock[node] || 0)
        end

        any_greater = @clock.any? do |node, timestamp|
          timestamp > (other_clock[node] || 0)
        end

        all_greater_or_equal && any_greater
      end
    end

    def to_h
      @mutex.synchronize { @clock.dup }
    end
  end

  class Raft
    STATES = [:follower, :candidate, :leader]

    attr_reader :state, :term, :voted_for

    def initialize(node_id, peers)
      @node_id = node_id
      @peers = peers
      @state = :follower
      @term = 0
      @voted_for = nil
      @log = []
      @commit_index = 0
      @last_applied = 0
      @election_timeout = rand(150..300) / 1000.0
      @last_heartbeat = Time.now
      @mutex = Mutex.new
    end

    def start_election
      @mutex.synchronize do
        @state = :candidate
        @term += 1
        @voted_for = @node_id
      end

      votes = 1
      votes_needed = (@peers.size / 2.0).ceil + 1

      @peers.each do |peer|
        vote = request_vote(peer)
        votes += 1 if vote
      end

      @mutex.synchronize do
        if votes >= votes_needed
          @state = :leader
          send_heartbeats
        else
          @state = :follower
        end
      end
    end

    def append_entry(entry)
      @mutex.synchronize do
        return false unless @state == :leader

        @log << { term: @term, entry: entry }
        replicate_log
        true
      end
    end

    def receive_heartbeat(leader_term)
      @mutex.synchronize do
        if leader_term >= @term
          @state = :follower
          @term = leader_term
          @last_heartbeat = Time.now
        end
      end
    end

    private

    def request_vote(peer)
      true
    end

    def send_heartbeats
      @peers.each do |peer|
        Thread.new do
          peer.receive_heartbeat(@term)
        end
      end
    end

    def replicate_log
    end
  end
end
