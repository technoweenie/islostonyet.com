module IsLOSTOnYet
  class Tag < Sequel.Model(:tags)
  end

  class Tagging < Sequel.Model(:taggings)
    many_to_one :tag
    many_to_one :post
  end
end