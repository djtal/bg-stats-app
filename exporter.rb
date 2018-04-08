require 'optparse'
require 'sequel'
require 'jbuilder'

DB = Sequel.connect(
  adapter: 'mysql2',
  host: 'localhost',
  user: 'root',
  database: 'ludomamager_prod_export'
)

f_parties = false
f_games = false
f_players = false
f_locations = false

# parse arguments
file = __FILE__
ARGV.options do |opts|
  opts.on("-p", "--parties") { f_parties = true }
  opts.on("-g", "--games") { f_games = true }
  opts.on("-y", "--players") { f_players = true }
  opts.on("-l", "--locations") { f_locations = true }
  opts.on_tail("-h", "--help") { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end

games_query = <<-SQL
  SELECT * from account_games
  INNER JOIN games ON account_games.game_id = games.id
  WHERE account_games.account_id = ?
SQL

parties_query = <<-SQL
  SELECT * FROM parties
  WHERE parties.account_id = ?
SQL

max_players_query = <<-SQL
  SELECT max(nb_player) AS max_player FROM parties
  WHERE parties.account_id = ?
SQL

run_date = Time.now

filename = "export-all.json"

games = DB[games_query, 1]
parties = DB[parties_query, 1]
max_players_count = DB[max_players_query, 1].first[:max_player]

data = Jbuilder.encode do |j|
  if f_games
    j.games do
      j.array! games do |game|
        j.id game[:id]
        j.name game[:name]
        j.modificationDate game[:transdate].strftime("%Y-%m-%d %H:%M")
      end
    end
  end
  if f_parties
    j.plays do
      j.array! parties do |party|
        j.ignored false
        j.rating 0
        j.scoringSetting 0
        j.gameRefId party[:game_id]
        j.locationRefId 1
        j.rounds 0
        j.manualWinner true
        j.useTeams false
        j.playDate party[:created_at].strftime("%Y-%m-%d %H:%M")
        j.entryDate run_date.strftime("%Y-%m-%d %H:%M")
        # players = Array.new([0, party[:nb_player].to_i].max) { {} }
        # if players.length > 0
        #   j.playerScores do
        #     j.array! players.each_with_index.to_a do |(_, index)|
        #       j.playerRefId index + 1
        #       j.seatOrder 0
        #       j.winner false
        #       j.rank 0
        #       j.startPlayer false
        #       j.newPlayer false
        #       j.score 0
        #     end
        #   end
        # end
      end
    end
  end
  if f_players
    j.players do
      players = Array.new([0, max_players_count.to_i].max) { {} }
      j.array! players.each_with_index.to_a do |(_, index)|
        j.id index + 1
        j.name "Anonymous player #{index}"
        j.isAnonymous true
        j.modificationDate run_date.strftime("%Y-%m-%d %H:%M")
      end
    end
  end
  if f_locations
    j.locations do
      j.array! Array.new(1).each_with_index.to_a do |(_, index)|
        j.id index + 1
        j.name "Home"
        j.modificationDate run_date.strftime("%Y-%m-%d %H:%M")
      end
    end
  end
end

File.open("./#{filename}", 'w') do |f|
  f << data
end

puts "Exported #{parties.count} parties" if f_parties
