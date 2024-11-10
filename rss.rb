#!/usr/bin/env ruby

require 'rss'
require 'json'
require 'open-uri'
require 'nokogiri'

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
    puts "source: #{rss.channel.title}"
    puts "-" * 60
    puts "-" * 60
    rss.items.each do |item|
      puts "title: #{item.title}"
      puts "publication date: #{item.pubDate}"
      puts "link: #{item.link}"

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

def get_urls(keywords)
  path = File.join(ENV['HOME'], ".rss")
  Dir.mkdir(path) unless Dir.exist?(path)
  content = JSON.parse(File.read(File.join(path, "feeds.json")))
  if keywords.include?("-a") || keywords.include?("--all") || keywords.empty?
    feeds = content.values.flatten
  else
    feeds = keywords.flat_map { |k| content.fetch(k, []) }
  end
  feeds.flatten
end

def fetch_rss_feed(url)
  URI.open(url) do |rss|
    feed = RSS::Parser.parse(rss)
    puts "source: #{feed.channel.title}"
    puts "-" * 60
    feed.items.each do |item|
      puts "title: #{item.title}"
      puts "publication date: #{item.pubDate}"
      puts "link: #{item.link}"
      puts "description: #{item.description}"
      puts "-" * 60
    end
  end
end

args = ARGV.map(&:downcase)
urls = get_urls(args)

urls.each do |url|
  if url.include?("propublica")
    parse_pro_publica(url)
  else
    fetch_rss_feed(url)
  end
end
