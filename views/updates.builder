atom_feed :xml => xml, :root_url => "/", :schema_date => IsLOSTOnYet.episodes.last.local_air_date.utc do |feed|
  feed.title(page_title)
  feed.updated(@posts.first.created_at)
  @posts.each do |post|
    user = @users[post.user_id]
    feed.entry(post, :url => "http://twitter.com/#{user.login}/status/#{post.external_id}") do |entry|
      entry.content(post.formatted_body, :type => 'html')

      entry.author do |author|
        author.name(user.login)
      end
    end
  end
end