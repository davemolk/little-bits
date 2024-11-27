require 'httparty'
require 'json'

module HttpUtils
  def self.fetch_json_data(url)
    res = HTTParty.get(url)
    unless res.success?
      warn "response error: #{res.code}" 
      puts res.body
      exit 1
    end
    JSON.parse(res.body)
  rescue JSON::ParserError
    warn "error parsing response"
    puts res.body
    exit 1
  end

  def self.fetch_data(url)
    res = HTTParty.get(url)
    unless res.success?
      warn "response error: #{res.code}" 
      puts res.body
      exit 1
    end
    res.body
  end
end