#!/usr/bin/env ruby

require 'csv'
require 'json'
require 'prettyprint'
require 'optparse'

class SchoolDirectory
  def initialize(options)
    @options = options
    @path = File.join(ENV['HOME'], '.school_contacts')
    keys = JSON.parse(File.read(File.join(@path, "names.json")))
    @first = keys["first"]
    @second = keys["second"]
  end

  def update
    case @options[:update]
    when @first
      update_first
    when @second
      update_second
    else
      puts "file name not recognized"
      exit 1
    end
  end

  def update_first()
    puts "updating first..."
    raw = File.open(File.join(@path, "#{@first}.csv")) do |f|
      CSV.parse(f)
    end

    h = raw[1..].each_with_object([]) do |row, obj|
      if row[0].include?("and")
        parents = row[0].split(" and ")
        emails = row[3].split(" & ")
        obj << [parents[0], row[1], row[2], emails[0]]
        obj << [parents[1], row[1], row[2], emails[1]]
      elsif row[0].include?("&")
        parents = row[0].split(" & ")
        emails = row[3].split(" & ")
        obj << [parents[0], row[1], row[2], emails[0]]
        obj << [parents[1], row[1], row[2], emails[1]]
      else
        obj << row
      end
    end

    re = /^[a-zA-z ]*/

    hash = h.each_with_object({}) do |row, obj|
      key = re.match(row[1])[0].strip.downcase
      if obj.key?(key)
        obj[key].push([row[0], row[2], row[3]])
      else
        obj[key] = [[row[0], row[2], row[3]]]
      end
    end
    File.write(File.join(@path, "#{@first}.json"), JSON.pretty_generate(hash))
  end

  def update_second()
    puts "updating second..."
    as_csv = CSV.table(File.open(File.join(@path, "#{@second}.csv")))

    new_hash = as_csv[1..].each_with_object({}) do |r, obj|
      obj[r[0].downcase] = [r[1..3], r[4..6]]
    end
    File.write(File.join(@path, "#{@second}.json"), JSON.pretty_generate(new_hash))

    old_hash = JSON.parse(File.read(File.join(@path, "#{@second}_old.json")))
    puts "file updated, merging..."
    merged_hash = old_hash.merge(new_hash) do |key, old_value, new_value|
      if new_hash.has_key?(key)
        old_value = old_value + new_value
        old_value.uniq
      else
        old_value
      end
    end
    File.write(File.join(@path, "#{@second}_all.json"), JSON.pretty_generate(merged_hash))
    puts "all files written, exiting..."
    exit 0
  end

  def search(key, names)
    path = ''
    case key
    when @first && @options[:all]
      path = File.join(@path, "#{@first}_all.json")
    when @first
      path = File.join(@path, "#{@first}.json")
    when @second && @options[:all]
      path = File.join(@path, "#{@second}_all.json")
    when @second
      path = File.join(@path, "#{@second}.json")
    else
      puts "key not recognized"
      exit 1
    end
    directory = JSON.parse(File.read(path))
    names.each do |name|
      directory.each do |key, values|
        next unless key.start_with?(name)

        values.each do |(name, phone, email)|
          case
          when @options[:name]
            p name if name
          when @options[:phone]
            p phone if phone
          when @options[:email]
            p email if email
          else
            p [name, phone, email].compact
          end
        end
      end
    end
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "usage: sd name <flags>"
  opts.on("-uFILE", "--update=FILE", "update from file") do |u| 
    options[:update] = u 
    options[:update_needed] = true
  end
  opts.on("-p", "--phone", "display phone numbers") { |p| options[:phone] = true }
  opts.on("-e", "--email", "display emails") { |e| options[:email] = true }
  opts.on("-n", "--name", "display names") { |n| options[:name] = true }
  opts.on("-a", "--all", "search all") { |a| options[:all] = true }
end.parse!

args = ARGV
args = args.map { |a| a.downcase }
school = SchoolDirectory.new(options)
school.update if options[:update_needed]

unless !args.empty?
  puts "need some args"
  exit 1
end

school.search(args[0], args[1..])