require 'morph'

module OsmCounty
  class << self

    def query_county point
      query = OpenstreetmapMatcher.query_cmd %'"is_in(#{point});
      area._[admin_level="6"];
      out meta;"'

      %[#{query} \
      | grep 'k="name"' \
      | sed -E 's/^.+v="([^"]+)".+/\\1/']
    end

    def get_county osm_feature
      lon, lat = osm_feature.point
      file = "./cache/county-enclosing-#{osm_feature.id.gsub('/','-')}.json"
      unless File.exist?(file)
        query = query_county "#{lat},#{lon}"
        `#{query} > #{file}`
      end
      IO.read(file).strip
    end

    def set_counties! osm_features
      osm_features.each do |f|
        f.county = get_county(f)
      end ; nil
    end

  end
end
