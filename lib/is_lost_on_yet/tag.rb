module IsLOSTOnYet
  class Tag < Sequel.Model(:tags)
    # taken from permalink_fu
    def self.escape(string)
      return "" if string.nil? || string.size.zero?
      result.gsub!(/[^\x00-\x7F]+/, '') # Remove anything non-ASCII entirely (e.g. diacritics).
      result.gsub!(/[^\w_ \-]+/i,   '') # Remove unwanted chars.
      result.gsub!(/[ \-]+/i,      '-') # No more than one of the separator in a row.
      result.gsub!(/^\-|\-$/i,      '') # Remove leading/trailing separator.
      result.downcase!
    end
  end

  class Tagging < Sequel.Model(:taggings)
    many_to_one :tag
    many_to_one :post
  end
end