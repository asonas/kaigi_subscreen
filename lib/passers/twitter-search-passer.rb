require_relative "passer"
require "uri"
require "yajl"
require "yajl/http_stream"

class TwitterSearchPasser < Passer
  def initialize(query)
    username = configatron.twitter.username
    password = configatron.twitter.password

    @query = query
    @ignore = configatron.twitter.ignore || []
    @auth   = "#{username}:#{password}"

    super(:stream, "tweet-#{query}")
  end

  def start
    prev    = nil
    current = Time.now.strftime("%Y%m%d%H")
    logfile = open(File.join(File.dirname(__FILE__), "..", "..", "db", "tweets", "#{@query}.#{current}"), "a+")

    uri = URI.parse("http://#{@auth}@stream.twitter.com/1/statuses/filter.json?track=#{URI.encode(@query)}")
    Yajl::HttpStream.get(uri) do |tweet|
      unless @ignore.include? tweet["user"]["screen_name"]
        p tweet
        pass(tweet)

        current = Time.now.strftime("%Y%m%d%H")
        unless current == prev
          logfile.close
          logfile = open(File.join(File.dirname(__FILE__), "..", "..", "db", "tweets", "#{@query}.#{current}"), "a+")
        end

        logfile.puts tweet

        prev = current
      end
    end

    logfile.close
  end
end

query = ARGV[0] || "rubykaigi"
p query

twitter = TwitterSearchPasser.new(query)
twitter.start
