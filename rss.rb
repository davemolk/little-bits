#!/usr/bin/env ruby

require 'rss'
require 'json'
require 'open-uri'
require 'nokogiri'

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def green
    colorize(32)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end
end

def limit_sentences(text, sentence_count = 5)
  # split text by sentence-ending punctuation (., !, ?)
  sentences = text.split(/(?<=[.!?])\s+/)
  sentences.each do |s|
    s.gsub!(/\n/, "")
    s.gsub!(/\s{2,}/, " ")
  end
  sentences.first(sentence_count).join(" ")
end

def parse_pro_publica(url)
  URI.open(url) do |rss_content|
    rss = RSS::Parser.parse(rss_content)
    puts "#{'source'.green}: #{rss.channel.title}"
    puts "-" * 60
    puts "-" * 60
    rss.items.each do |item|
      puts "#{'title'.pink}: #{item.title}"
      puts "#{'date'.blue}: #{item.pubDate}"
      puts "#{'link'.pink}: #{item.link}"

      # pita
      description_html = Nokogiri::HTML(item.description)
  
      description_html.traverse do |node|
        if node.text?
          node.content = node.content.tr("’", "'")
        end
      end
      
      description_text = ''
      description_html.css('p').each do |p|
        if p['data-pp-id']&.start_with?('1.')
          description_text += p.text.strip
        elsif p['data-pp-id']&.start_with?('2.')
          description_text += p.text.strip
        elsif p['data-pp-id']&.start_with?('3.')
          description_text += p.text.strip
        end
      end
  
      limited_description = limit_sentences(description_text, 5)
      p limited_description
  
      puts "-" * 60
    end
  end
end

def fetch_rss_feed(url)
  URI.open(url) do |rss_content|
    rss = RSS::Parser.parse(rss_content)
    puts "#{'source'.green}: #{rss.channel.title}"
    puts "-" * 60
    puts "-" * 60
    rss.items.each do |item|
      puts "#{'title'.pink}: #{item.title}"
      puts "#{'date'.blue}: #{item.pubDate}"
      puts "#{'link'.pink}: #{item.link}"
      description_html = Nokogiri::HTML(item.description)
      puts "#{'description'.blue}: #{description_html.text}"
      puts "-" * 60
    end
  end
end

def get_urls(keywords)
  path = File.join(ENV['HOME'], ".rss")
  Dir.mkdir(path) unless Dir.exist?(path)
  content = JSON.parse(File.read(File.join(path, "feeds.json")))
  if keywords.empty?
    feeds = content.values.flatten.uniq
  elsif keywords[0] == 'topics'
    p content.keys
    exit 0
  else
    feeds = keywords.flat_map { |k| content.fetch(k, []) }
  end
  feeds.flatten.uniq
end

args = ARGV

case args[0]
when 'help', 'h', '--help', '-h'
  puts "enter a topic or leave blank for all"
  puts "enter 'topics' for a list of available topics"
end

urls = get_urls(args)

urls.each do |url|
  if url.include?("propublica")
    parse_pro_publica(url)
  else
    parse_the_intercept(url)
  end
end
