require 'twilio-ruby'

class SmsSender
  def initialize
    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token = ENV['TWILIO_AUTH_TOKEN']
    @from_number = ENV['TWILIO_PHONE_NUMBER']

    @client = Twilio::REST::Client.new(account_sid, auth_token) if account_sid && auth_token
  end

  def send_sms(to:, message:)
    return { status: 'disabled', message: 'Twilio not configured' } unless @client

    message = @client.messages.create(
      from: @from_number,
      to: to,
      body: message
    )

    { status: 'sent', sid: message.sid }
  rescue => e
    { status: 'failed', error: e.message }
  end

  def send_bulk_sms(recipients:, message:)
    results = []

    recipients.each do |recipient|
      result = send_sms(to: recipient, message: message)
      results << { recipient: recipient, result: result }
    end

    results
  end
end
