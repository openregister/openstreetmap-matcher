module OsmFeature
  class << self
    def query_features type, bounds, options
      capitalised_type = type.capitalize
      query = "[out:json][timeout:60][bbox:#{bounds}];
      (
        node['amenity'='#{type}'];
        relation['amenity'='#{type}'];
        way['amenity'='#{type}'];"
      if options.has_key?(:match_on) && options[:match_on].include?(:name)
        query = query + "
        relation['building']['name'~'.*#{capitalised_type}.*'];
        node['building']['name'~'.*#{capitalised_type}.*'];
        way['building']['name'~'.*#{capitalised_type}.*'];"
      end
      query = query + "
        node['building'='#{type}'];
        relation['building'='#{type}'];
        way['building'='#{type}'];
      );
      out body;
      >;
      out skel qt;"
      OpenstreetmapMatcher.query_cmd_to_geojson query
    end

    def get_features name, type, bounds, options={}
      file = "./cache/#{type}.json"
      unless File.exist? file
        query = query_features(type, bounds, options)
        `#{query} > #{file}`
      end
      hash = eval(IO.read(file).gsub('@id','id'))
      features = Morph.from_hash(name => hash[:features])
      hash = nil
      features
    end
  end

  def name
    properties.name
  end

  def coordinates
    geometry.coordinates
  end

  def building?
    properties.try(:building).present?
  end

  def kind
    if building?
      'building'
    else
      id.split('/').first
    end
  end

  # naive point calculated as average of points in geometry polygons
  def point
    x = []
    y = []
    case geometry.type
    when 'MultiPolygon'
      coordinates.each { |list| append_list list, x, y }
    when 'LineString'
      append coordinates, x, y
    when 'Point'
      x << coordinates.first
      y << coordinates.last
    else
      append_list coordinates, x, y
    end
    lon = x.reduce(&:+) / x.size
    lat = y.reduce(&:+) / y.size
    [lon.round(7), lat.round(7)]
  end

  private

  def append_list list, x, y
    list.each { |coordinates| append coordinates, x, y }
  end

  def append coordinates, x, y
    coordinates.each do |x_lon, y_lat|
      x << x_lon
      y << y_lat
    end
  end
end
