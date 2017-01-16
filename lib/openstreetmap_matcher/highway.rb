require 'morph'

class Morph::Highway
  include Morph

  def name
    properties.name
  end
end
