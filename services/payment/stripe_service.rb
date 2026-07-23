require 'stripe'

module PaymentService
  class StripeService
    def initialize
      Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    end

    def create_customer(email, name)
      Stripe::Customer.create(
        email: email,
        name: name
      )
    end

    def create_payment_intent(amount, currency, customer_id)
      Stripe::PaymentIntent.create(
        amount: amount,
        currency: currency,
        customer: customer_id,
        payment_method_types: ['card']
      )
    end

    def create_subscription(customer_id, price_id)
      Stripe::Subscription.create(
        customer: customer_id,
        items: [{ price: price_id }]
      )
    end

    def cancel_subscription(subscription_id)
      subscription = Stripe::Subscription.retrieve(subscription_id)
      subscription.cancel
    end

    def refund_payment(payment_intent_id)
      Stripe::Refund.create(payment_intent: payment_intent_id)
    end
  end
end
