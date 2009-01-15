module IsLOSTOnYet
  class Tag < Sequel.Model(:tags)
    def self.list
      Sequel::Model.db[:tags].group(:name).inner_join(:taggings, :tag_id => :id).select(:name, :COUNT[:post_id]).order(:name).map do |row|
        # the different 'name' columns have to do with how sequel interprets rows from mysql vs sqlite
        [row[:name] || row[:"`name`"], row[:"COUNT(`post_id`)"].to_i]
      end
    end
  end

  class Tagging < Sequel.Model(:taggings)
    many_to_one :tag,  :class => "IsLOSTOnYet::Tag"
    many_to_one :post, :class => "IsLOSTOnYet::Post"
  end
end