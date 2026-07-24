require 'rspec'
require_relative '../../services/ruby/authentication'

RSpec.describe Authentication::TokenManager do
  let(:secret) { 'test_secret' }
  let(:manager) { Authentication::TokenManager.new(secret) }

  describe '#generate_token' do
    it 'generates a valid token' do
      token = manager.generate_token({ user_id: 1 })
      expect(token).to be_a(String)
      expect(token.length).to be > 0
    end
  end

  describe '#validate_token' do
    it 'validates a token and returns payload' do
      payload = { user_id: 1, email: 'test@example.com' }
      token = manager.generate_token(payload)
      expect(manager.validate_token(token)).to eq(payload)
    end
  end
end
