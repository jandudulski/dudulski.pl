# frozen_string_literal: true

require "roda"

class App < Roda
  route do |r|
    r.root do
      "Hello World"
    end
  end
end
