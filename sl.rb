#!/usr/bin/env ruby

require 'httparty'
require 'json'
require 'date'

CONFIG_PATH = File.join(ENV['HOME'], "/.lunch/config.json")

def load_config
  JSON.parse(File.read(CONFIG_PATH))
rescue EOFError::ENOENT
  puts "config file not found #{CONFIG_PATH}"
  exit 1
rescue JSON::ParserError
  puts "error parsing json"
  exit 1
end

def get_day
  if Date.today.sunday? || Date.today.saturday?
    puts "no school on the weekend"
    exit 1
  end
  Date.today
end

def format_date(date)
  month = format('%02d', date.month)
  "#{month}%2F#{date.day}%2F#{date.year}"
end

def build_url(school_id, grade, date)
  base = "https://webapis.schoolcafe.com/api/CalendarView/GetDailyMenuitemsByGrade?SchoolId="
  "#{base}#{school_id}&ServingDate=#{date}&ServingLine=Traditional%20Lunch&MealType=Lunch&Grade=#{grade}&PersonId=null"
end

def get_lunch(url)
  res = HTTParty.get(url)
  unless res.code == 200
    puts "got response code: #{res.code}"
    puts res.body
    exit 1
  end
  JSON.parse(res.body)
rescue JSON::ParserError
  puts "error parsing json"
  exit 1
end

def display_lunch(lunch)
  # because that one day they used entrees...
  ['ENTREE', 'ENTREES'].each do |key|
    if lunch.key?(key)
      lunch[key].each { |item| puts item["MenuItemDescription"] }
    end
  end
end

date = format_date(get_day)
config = load_config()
school_id = config["school_id"]
grade = config["grade"]

url = build_url(school_id, grade, date)

puts "checking school lunch...\n\n"
lunch = get_lunch(url)
display_lunch(lunch)