require 'oj'

class BGStatAppExportReader
  attr_reader :file, :section

  def initialize(file:, section:)
    @file = file
    @section = section
  end

  def each
    json = Oj.load(File.read(file), symbol_key: true)

    json[section].each do |game|
      yield game
    end
  end
end
