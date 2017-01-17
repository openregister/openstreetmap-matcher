require 'morph'

module OsmWay
  class << self

    def query_highways bounds
      OpenstreetmapMatcher.query_cmd_to_geojson "[out:json][timeout:60][bbox:#{bounds}];
      (
        way[name][highway];
      );
      out body;
      >;
      out skel qt;"
    end

    def nearby_bounds school, x_lon_delta=0.003, y_lat_delta=0.0015
      lon, lat = school.point
      west = lon - x_lon_delta
      east = lon + x_lon_delta
      south = lat - y_lat_delta
      north = lat + y_lat_delta
      bounds = [south, west, north, east].map{|x| x.round(4)}.join(',')
    end

    def get_ways osm_feature, x_lon_delta=0.003, y_lat_delta=0.0015
      bounds = nearby_bounds(osm_feature, x_lon_delta, y_lat_delta)
      file = "./cache/highways-near-#{osm_feature.id.tr('/','-')}-#{bounds.gsub(',','-')}.json"
      `#{query_highways bounds} > #{file}` unless File.exist?(file)
      IO.read(file)
    end

    def normalize_name text
      if text
        text.gsub(/\d/,'').tr('-',' ').tr("'",'').strip.upcase
      else
        text
      end
    end

    def set_nearby_ways! osm_features
      osm_features.each do |s|
        hash = eval get_ways(s)
        ways = Morph.from_hash(highways: hash[:features])
        if ways.blank?
          hash = eval get_ways(s, 0.016, 0.007)
          begin
            ways = Morph.from_hash(highways: hash[:features])
          rescue Exception => e
            binding.pry
            raise e
          end
        end
        s.nearby_ways = ways
        s.nearby_streets = ways.map(&:name).map{|x| normalize_name x }
      end ; nil
    end

  end
end
