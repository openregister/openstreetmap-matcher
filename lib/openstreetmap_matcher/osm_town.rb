require 'morph'

module OsmTown
  class << self

    def query_town point
      %[echo "is_in(#{point});
      area._['place'~'city|town|village|hamlet']->.a;
      area._['admin_level'='10']->.b;
      area._['public_transport'='pay_scale_area'][name]->.c;
      .a out tags;
      .b out tags;
      .c out tags;" > tmp-query.osm

      curl -s -X POST -d @tmp-query.osm http://overpass-api.de/api/interpreter \
      | grep 'k="name"' \
      | sed -E 's/^.+v="([^"]+)".+/\\1/']
    end

    def get_town osm_feature
      lon, lat = osm_feature.point
      file = "./cache/town-enclosing-#{osm_feature.id.gsub('/','-')}.json"
      unless File.exist?(file)
        query = query_town "#{lat},#{lon}"
        `#{query} > #{file}`
      end
      IO.read(file).strip
    end

    def set_towns! osm_features
      osm_features.each do |f|
        f.osm_town = get_town(f)
      end ; nil
    end

  end
end
