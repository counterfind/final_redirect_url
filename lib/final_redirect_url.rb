require 'final_redirect_url/version'
require 'net/http'
require 'logger'

module FinalRedirectUrl

  def self.final_redirect_url(url, options = {})
    @final_url = url

    if valid_url?(url)
      begin
        redirect_lookup_depth = options[:depth].to_i.positive? ? options[:depth].to_i : 5
        timeout = options[:timeout].to_i.positive? ? options[:timeout].to_i : 3

        response_uri = get_final_redirect_url(url, redirect_lookup_depth, timeout)
        @final_url = url_string_from_uri(response_uri)
      rescue Exception => ex
        logger = Logger.new(STDOUT)
        logger.error(ex.message)
      end
    end

    @final_url
  end

  private

  def self.valid_url?(url)
    url.to_s =~ /\A#{URI.regexp(%w[http https])}\z/
  end

  def self.get_final_redirect_url(url, limit = 5, timeout = 3)
    return url if limit <= 0

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = timeout
    http.open_timeout = timeout
    response = http.start do |http|
      http.get(uri.path)
    end
    return uri if response.class == Net::HTTPOK

    redirect_location = response['location']
    return uri unless redirect_location

    location_uri = URI.parse(redirect_location)
    if location_uri.host.nil?
      redirect_location = uri.scheme + '://' + uri.host + redirect_location
    end
    @final_url = redirect_location
    get_final_redirect_url(redirect_location, limit - 1, timeout)
  end

  def self.url_string_from_uri(uri)
    url_str = "#{uri.scheme}://#{uri.host}#{uri.request_uri}"
    url_str += "##{uri.fragment}" if uri.fragment
    url_str
  end
end
