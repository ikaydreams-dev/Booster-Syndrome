require 'net/http'
require 'json'
require 'securerandom'

module Payments
  class Transaction
    attr_reader :id, :amount, :currency, :status, :payment_method, :created_at, :metadata

    def initialize(amount:, currency: 'USD', payment_method:, metadata: {})
      @id = SecureRandom.uuid
      @amount = amount
      @currency = currency
      @payment_method = payment_method
      @status = :pending
      @created_at = Time.now
      @metadata = metadata
      @error = nil
    end

    def complete!
      @status = :completed
    end

    def fail!(error)
      @status = :failed
      @error = error
    end

    def refund!
      @status = :refunded
    end

    def to_h
      {
        id: @id,
        amount: @amount,
        currency: @currency,
        status: @status,
        payment_method: @payment_method,
        created_at: @created_at.iso8601,
        metadata: @metadata,
        error: @error
      }
    end
  end

  class PaymentProcessor
    def initialize
      @transactions = {}
      @mutex = Mutex.new
    end

    def create_transaction(amount:, currency: 'USD', payment_method:, metadata: {})
      transaction = Transaction.new(
        amount: amount,
        currency: currency,
        payment_method: payment_method,
        metadata: metadata
      )

      @mutex.synchronize do
        @transactions[transaction.id] = transaction
      end

      transaction
    end

    def get_transaction(transaction_id)
      @mutex.synchronize do
        @transactions[transaction_id]
      end
    end

    def process_payment(transaction_id, payment_details: {})
      transaction = get_transaction(transaction_id)
      return { success: false, error: 'Transaction not found' } unless transaction

      begin
        case transaction.payment_method
        when :credit_card
          process_credit_card(transaction, payment_details)
        when :paypal
          process_paypal(transaction, payment_details)
        when :stripe
          process_stripe(transaction, payment_details)
        else
          { success: false, error: 'Unsupported payment method' }
        end
      rescue => e
        transaction.fail!(e.message)
        { success: false, error: e.message }
      end
    end

    def refund(transaction_id, amount: nil)
      transaction = get_transaction(transaction_id)
      return { success: false, error: 'Transaction not found' } unless transaction

      refund_amount = amount || transaction.amount

      transaction.refund!

      {
        success: true,
        transaction_id: transaction_id,
        refunded_amount: refund_amount
      }
    end

    def list_transactions(status: nil)
      @mutex.synchronize do
        transactions = @transactions.values

        if status
          transactions = transactions.select { |t| t.status == status }
        end

        transactions.sort_by { |t| -t.created_at.to_i }
      end
    end

    private

    def process_credit_card(transaction, details)
      transaction.complete!

      {
        success: true,
        transaction_id: transaction.id,
        amount: transaction.amount,
        currency: transaction.currency
      }
    end

    def process_paypal(transaction, details)
      transaction.complete!

      {
        success: true,
        transaction_id: transaction.id,
        amount: transaction.amount,
        currency: transaction.currency
      }
    end

    def process_stripe(transaction, details)
      transaction.complete!

      {
        success: true,
        transaction_id: transaction.id,
        amount: transaction.amount,
        currency: transaction.currency
      }
    end
  end

  class Subscription
    attr_reader :id, :plan_id, :user_id, :status, :current_period_start, :current_period_end

    def initialize(plan_id:, user_id:, billing_cycle: :monthly)
      @id = SecureRandom.uuid
      @plan_id = plan_id
      @user_id = user_id
      @status = :active
      @billing_cycle = billing_cycle
      @current_period_start = Time.now
      @current_period_end = calculate_period_end
      @created_at = Time.now
    end

    def cancel
      @status = :cancelled
    end

    def pause
      @status = :paused
    end

    def resume
      @status = :active
    end

    def renew
      @current_period_start = Time.now
      @current_period_end = calculate_period_end
    end

    def active?
      @status == :active && Time.now < @current_period_end
    end

    def to_h
      {
        id: @id,
        plan_id: @plan_id,
        user_id: @user_id,
        status: @status,
        current_period_start: @current_period_start.iso8601,
        current_period_end: @current_period_end.iso8601,
        created_at: @created_at.iso8601
      }
    end

    private

    def calculate_period_end
      case @billing_cycle
      when :monthly
        @current_period_start + 30 * 24 * 60 * 60
      when :yearly
        @current_period_start + 365 * 24 * 60 * 60
      when :weekly
        @current_period_start + 7 * 24 * 60 * 60
      else
        @current_period_start + 30 * 24 * 60 * 60
      end
    end
  end

  class SubscriptionManager
    def initialize(payment_processor)
      @payment_processor = payment_processor
      @subscriptions = {}
      @plans = {}
      @mutex = Mutex.new
    end

    def create_plan(id:, name:, amount:, currency: 'USD', billing_cycle: :monthly)
      @mutex.synchronize do
        @plans[id] = {
          id: id,
          name: name,
          amount: amount,
          currency: currency,
          billing_cycle: billing_cycle
        }
      end
    end

    def subscribe(user_id:, plan_id:)
      plan = @plans[plan_id]
      return { success: false, error: 'Plan not found' } unless plan

      subscription = Subscription.new(
        plan_id: plan_id,
        user_id: user_id,
        billing_cycle: plan[:billing_cycle]
      )

      transaction = @payment_processor.create_transaction(
        amount: plan[:amount],
        currency: plan[:currency],
        payment_method: :credit_card,
        metadata: { subscription_id: subscription.id }
      )

      @mutex.synchronize do
        @subscriptions[subscription.id] = subscription
      end

      {
        success: true,
        subscription: subscription,
        transaction: transaction
      }
    end

    def cancel_subscription(subscription_id)
      subscription = @subscriptions[subscription_id]
      return { success: false, error: 'Subscription not found' } unless subscription

      subscription.cancel

      { success: true, subscription: subscription }
    end

    def get_subscription(subscription_id)
      @subscriptions[subscription_id]
    end

    def list_subscriptions(user_id: nil, status: nil)
      @mutex.synchronize do
        subscriptions = @subscriptions.values

        subscriptions = subscriptions.select { |s| s.user_id == user_id } if user_id
        subscriptions = subscriptions.select { |s| s.status == status } if status

        subscriptions
      end
    end

    def process_renewals
      @subscriptions.values.each do |subscription|
        next unless subscription.active?
        next if Time.now < subscription.current_period_end

        plan = @plans[subscription.plan_id]
        next unless plan

        transaction = @payment_processor.create_transaction(
          amount: plan[:amount],
          currency: plan[:currency],
          payment_method: :credit_card,
          metadata: { subscription_id: subscription.id, renewal: true }
        )

        result = @payment_processor.process_payment(transaction.id)

        if result[:success]
          subscription.renew
        else
          subscription.cancel
        end
      end
    end
  end

  class Invoice
    attr_reader :id, :user_id, :items, :total, :status, :created_at

    def initialize(user_id:)
      @id = SecureRandom.uuid
      @user_id = user_id
      @items = []
      @total = 0
      @status = :draft
      @created_at = Time.now
    end

    def add_item(description:, amount:, quantity: 1)
      @items << {
        description: description,
        amount: amount,
        quantity: quantity,
        total: amount * quantity
      }

      calculate_total
    end

    def finalize!
      @status = :finalized
    end

    def pay!
      @status = :paid
    end

    def to_h
      {
        id: @id,
        user_id: @user_id,
        items: @items,
        total: @total,
        status: @status,
        created_at: @created_at.iso8601
      }
    end

    private

    def calculate_total
      @total = @items.sum { |item| item[:total] }
    end
  end
end
