#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'httparty'
require 'date'
require 'uri'


# play around w/ https://github.com/internetarchive/wayback/tree/master/wayback-cdx-server if needed
# this api is called from the front but prob takes some/most of the same
def build_url(domain, limit)
  now = Time.now.to_i
  "https://web.archive.org/web/timemap/json?url=#{domain}&matchType=prefix&collapse=urlkey&output=json&fl=original%2Cmimetype%2Ctimestamp%2Cendtimestamp%2Cgroupcount%2Cuniqcount&filter=!statuscode%3A%5B45%5D..&limit=#{limit}&_=#{now}"
end

def get_data(url)
  res = HTTParty.get(url)
  raise "response error: #{res.code}" unless res.success?
  JSON.parse(res.body)
rescue JSON::ParserError
  warn "error parsing response"
  puts res.body
  exit 1
end

def print_urls(data)
  data.each { |row| puts row[0] }
end

def print_data(data)
  got_format = '%Y%m%d%H%M%S'
  want_format = '%Y-%m-%d'
  data.each do |row|
    time = DateTime.strptime(row[2], got_format)
    timestamp = time.strftime(want_format)
    end_time = DateTime.strptime(row[3], got_format)
    end_timestamp = end_time.strftime(want_format)
    puts <<~DATA
    url:          #{row[0]}
    mimetype:     #{row[1]}
    from:    #{timestamp}
    to:     #{end_timestamp}
    group_count:  #{row[4]}
    unique_count: #{row[5]}
    DATA
  end
end

options = {
  :limit => 10000,
}
OptionParser.new do |opts|
  opts.on("-k", "--key", "display key for the json output") { options[:key] = true }
  opts.on("-v", "--verbose", "verbose output") { options[:verbose] = true }
  opts.on("-l", "--limit LIMIT", "results limit (default 10000)") { |l| options[:limit] = l }
  opts.on("-f", "--from FROM", "from", "filter by from, use yyyyMMddhhmmss or some subset of it") { |f| options[:from] = f }
  opts.on("-t", "--to TO", "filter by to, use yyyyMMddhhmmss or some subset of it") { |t| options[:to] = t }
end.parse!

if ARGV.empty?
  warn "need a domain to search"
  exit 1
end

if options[:key]
  # hard-code cause we determine via url, save a request  
  puts '[ "original", "mimetype", "timestamp", "endtimestamp", "groupcount", "uniqcount" ]'
end

domain = ARGV[0]

url = (build_url(domain, options[:limit]))
url = "#{url}&from=#{options[:from]}" if options[:from]
url = "#{url}&to=#{options[:to]}" if options[:to]

data = get_data(url)

# first is always the key
if data.length < 2
  puts "no results for #{domain}"
end

options[:verbose] ? print_data(data[1..]) : print_urls(data[1..])
