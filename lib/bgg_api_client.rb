require "http"
require "nokogiri"

class BGGAPIClient
  BASE_URL = "https://api.geekdo.com/xmlapi2".freeze

  attr_reader :http

  def initialize
  end

  def get(thing:, id:)
    HTTP
      .headers(accept: "application/xml")
      .get("#{BASE_URL}/thing", params: { id: id })
  end

  def get_game(id:)
    res = get(thing: :game, id: id)
    if res.status.success?
      Nokogiri::XML(res.body)
    end
  end
end
