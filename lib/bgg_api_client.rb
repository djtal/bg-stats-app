require "http"

class BGGAPIClient
  BASE_URL = "https://www.boardgamegeek.com/xmlapi2/".freeze

  attr_reader :http

  def initialize
    @http = HTTP.persistent BASE_URL
  end

  def get(thing:, id:)
    http.get("/thing", params: { thing: thing, id: id }).flush
  end

  def get_game(id:)
    get(thing: :game, id: id)
  end
end
