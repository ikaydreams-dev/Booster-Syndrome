require 'json'
require 'net/http'

class ReportJob
  def perform
    puts "Generating daily report at #{Time.now}"

    data = fetch_analytics_data
    report = generate_report(data)
    send_report(report)

    puts "Report sent successfully!"
  end

  private

  def fetch_analytics_data
    uri = URI('http://localhost:8003/api/v1/stats/summary')
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  rescue => e
    puts "Error fetching data: #{e.message}"
    {}
  end

  def generate_report(data)
    {
      date: Date.today,
      total_events: data['total_events'] || 0,
      unique_users: data['unique_users'] || 0,
      growth_rate: calculate_growth(data),
      generated_at: Time.now
    }
  end

  def calculate_growth(data)
    # Calculate growth rate
    0.0
  end

  def send_report(report)
    # Send report via email or save to file
    File.write("reports/daily_#{Date.today}.json", report.to_json)
  end
end
