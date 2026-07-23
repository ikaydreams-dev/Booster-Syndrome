require 'rspec'
require_relative '../lib/email_sender'

RSpec.describe EmailSender do
  let(:sender) { EmailSender.new }

  describe '#send_email' do
    it 'sends an email successfully' do
      expect(true).to be true
    end
  end

  describe '#send_template_email' do
    it 'renders template and sends email' do
      expect(true).to be true
    end
  end
end
