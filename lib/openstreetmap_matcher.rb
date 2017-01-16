require 'morph'
require_relative 'openstreetmap_matcher/highway'
require_relative 'openstreetmap_matcher/osm_county'
require_relative 'openstreetmap_matcher/osm_feature'
require_relative 'openstreetmap_matcher/osm_town'
require_relative 'openstreetmap_matcher/osm_way'

module OpenstreetmapMatcher

  class << self

    def query_cmd overpass_query
      %'echo "#{overpass_query}" > tmp-query.osm && \
      curl -s -X POST -d @tmp-query.osm http://overpass-api.de/api/interpreter \
      | osmtogeojson'
    end

    def osm_features name, types, bounds, options={}
      features = types.map do |type|
        OsmFeature.get_features name, type, bounds, options
      end.flatten
      if options.has_key?(:include)
        OsmCounty.set_counties! features if options[:include].include?(:county)
        OsmTown.set_towns! features if options[:include].include?(:town)
        OsmWay.set_nearby_ways! features if options[:include].include?(:nearby_ways)
      end
      features
    end

    def street_match? street, locality, nearby_streets
      nearby_streets.present? &&
      (nearby_streets.include?(street) || nearby_streets.include?(locality))
    end

    def town_match? address_parts, osm_town
      osm_town.present? && address_parts.include?(osm_town.sub(' CP',''))
    end

    def write_points_tsv primary_key_field, features, file
      File.open(file, 'w') do |f|
        f.puts ([primary_key_field] + %w[address point]).join("\t")
        features.each do |s|
          f.puts [s.send(primary_key_field), s.address, s.point.to_s].join("\t")
        end
      end ; nil
    end
  end
end
