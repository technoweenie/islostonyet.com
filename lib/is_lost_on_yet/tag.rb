module IsLOSTOnYet
  class Tag < Sequel.Model(:tags)
  end

  class Tagging < Sequel.Model(:taggings)
    many_to_one :tag,  :class => "IsLOSTOnYet::Tag"
    many_to_one :post, :class => "IsLOSTOnYet::Post"
  end
end