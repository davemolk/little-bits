#!/usr/bin/env ruby

require 'optparse'
require './http_utils.rb'

URL_HOTTEST = "https://lobste.rs/hottest.json"
URL_NEWEST = "https://lobste.rs/newest.json"

options = {}
OptionParser.new do |opts|
  opts.banner = "usage: lob [options]"
  opts.on("-h", "--hot", "get hottest") { options[:hot] = true }
end.parse!

def find_single_match(input, data)
  matches = data.select do |p|
    p["title"].downcase.start_with?(input) || p["short_id"].downcase.start_with?(input)
  end

  case matches.length
  when 0
    puts "no matches found"
    exit 1
  when 1
    matches.first
  else
    puts "multiple matches found: #{matches}"
    exit 1
  end
end

url = options[:hot] ? URL_HOTTEST : URL_NEWEST

parsed_posts = HttpUtils.fetch_json_data(url)

parsed_posts.each do |p|
  puts <<~OUTPUT
    title:          #{p["title"]}
    url:            #{p["url"]}
    tags:           #{p["tags"]}
    comment count:  #{p["comment_count"]}
    id:             #{p["short_id"]}\n
  OUTPUT
end

puts "type 'open <id>' to open the url in a browser, the <id> to see the post's comments, or press any key to quit."
puts "(you can enter a fragment of a post's title instead of the id, or 'exit' to quit)"
input = gets.chomp.rstrip.downcase

exit 0 if input == 'exit'

if input.start_with?("open ")
  if input.length < 6
    puts "to open a url in a browser, format as 'open s2zxwx' or 'open <fragment of the title>'"
    exit 1
  end
  fragment = input[5..]
  match = find_single_match(fragment, parsed_posts)
  system("open #{match["url"]}")
else
  match = find_single_match(input, parsed_posts)
  if match["comment_count"] == 0
    warn("#{match["title"]} has no comments")
    exit 1
  end
  comment_url = "https://lobste.rs/s/#{match["short_id"]}.json"
  parsed_comments = HttpUtils.fetch_json_data(comment_url)

  comment_depth = parsed_comments["comments"].each_with_object({}) do |c, m|
    m[c["short_id"]] = (m[c["parent_comment"]] || -1) + 1
  end

  parsed_comments["comments"].each do |c|
    prefix = "\t" * comment_depth[c["short_id"]]
    puts "\n#{prefix}* #{c["comment_plain"].gsub("\r\n\r\n", " ")}"
  end
end
