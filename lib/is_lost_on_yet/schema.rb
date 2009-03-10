module IsLOSTOnYet
  def self.setup_schema
    Sequel::Model.db.instance_eval do
      create_table! :users do
        primary_key :id
        int         :external_id
        varchar     :login
        varchar     :avatar_url
      end

      create_table! :posts do
        primary_key :id
        int         :external_id
        int         :user_id
        varchar     :body # 140 chars, baby
        datetime    :created_at
        boolean     :visible
      end
    end
  end
end