module IsLOSTOnYet
  class Post < Sequel.Model(:posts)
    def self.process_site_posts
    end

    def self.process_responses
    end
  end
end