require 'time'
require 'date'

module DateTimeUtils
  class TimeHelper
    def self.now
      Time.now
    end

    def self.today
      Date.today
    end

    def self.format(time, format = '%Y-%m-%d %H:%M:%S')
      time.strftime(format)
    end

    def self.parse(time_string)
      Time.parse(time_string)
    end

    def self.timestamp
      Time.now.to_i
    end

    def self.timestamp_ms
      (Time.now.to_f * 1000).to_i
    end

    def self.from_timestamp(timestamp)
      Time.at(timestamp)
    end

    def self.add_days(time, days)
      time + (days * 24 * 60 * 60)
    end

    def self.add_hours(time, hours)
      time + (hours * 60 * 60)
    end

    def self.add_minutes(time, minutes)
      time + (minutes * 60)
    end

    def self.diff_in_days(time1, time2)
      ((time1 - time2) / (24 * 60 * 60)).to_i
    end

    def self.diff_in_hours(time1, time2)
      ((time1 - time2) / (60 * 60)).to_i
    end

    def self.diff_in_minutes(time1, time2)
      ((time1 - time2) / 60).to_i
    end

    def self.start_of_day(time)
      Time.new(time.year, time.month, time.day, 0, 0, 0)
    end

    def self.end_of_day(time)
      Time.new(time.year, time.month, time.day, 23, 59, 59)
    end

    def self.start_of_week(time)
      time - (time.wday * 24 * 60 * 60)
    end

    def self.end_of_week(time)
      start_of_week(time) + (6 * 24 * 60 * 60)
    end

    def self.start_of_month(time)
      Time.new(time.year, time.month, 1)
    end

    def self.end_of_month(time)
      next_month = time.month == 12 ? 1 : time.month + 1
      next_year = time.month == 12 ? time.year + 1 : time.year
      Time.new(next_year, next_month, 1) - 1
    end

    def self.is_weekend?(time)
      time.saturday? || time.sunday?
    end

    def self.is_past?(time)
      time < Time.now
    end

    def self.is_future?(time)
      time > Time.now
    end

    def self.is_today?(time)
      time.to_date == Date.today
    end

    def self.time_ago_in_words(time)
      diff = Time.now - time

      case diff
      when 0..59
        'just now'
      when 60..3599
        "#{(diff / 60).to_i} minutes ago"
      when 3600..86399
        "#{(diff / 3600).to_i} hours ago"
      when 86400..2591999
        "#{(diff / 86400).to_i} days ago"
      else
        time.strftime('%Y-%m-%d')
      end
    end
  end
end
