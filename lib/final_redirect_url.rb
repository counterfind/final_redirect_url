require 'final_redirect_url/version'
require 'net/http'
require 'logger'

module FinalRedirectUrl

  def self.final_redirect_url(url, options={})
    final_url = url
    if is_valid_url?(url)
      begin
        redirect_lookup_depth = options[:depth].to_i > 0 ? options[:depth].to_i : 5
        response_uri = get_final_redirect_url(url, redirect_lookup_depth)
        final_url =  url_string_from_uri(response_uri)
      rescue Exception => ex
        logger = Logger.new(STDOUT)
        logger.error(ex.message)
      end
    end
    final_url
  end

  private

  def self.is_valid_url?(url)
    url.to_s =~ /\A#{URI::regexp(['http', 'https'])}\z/
  end

  def self.get_final_redirect_url(url, limit = 5)
    return url if limit <= 0

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 3
    http.open_timeout = 3
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
    get_final_redirect_url(redirect_location, limit - 1)
  end

  def self.url_string_from_uri(uri)
    url_str = "#{uri.scheme}://#{uri.host}#{uri.request_uri}"
    url_str += "##{uri.fragment}" if uri.fragment
    url_str
  end
end
