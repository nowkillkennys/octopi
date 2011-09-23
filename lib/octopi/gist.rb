module Octopi
  class Gist < Base
    autoload :Comment, "octopi/gist/comment"
    autoload :GistFile, "octopi/gist/gist_file"
    autoload :History, "octopi/gist/history"
    
    def self.for_user(user)
      collection("/users/#{user}/gists")
    end
    
    # Will retreive all gists for a user if authenticated.
    # Otherwise, all gists, ordered in reverse order by creation time
    def self.mine
      all
    end
    
    def self.starred
      Octopi.requires_authentication! do
        collection("/gists/starred")
      end
    end

    def initialize(attributes)
      super
      @attributes[:public] = true unless @attributes[:public] == false
      # Link files, history and comments to this gist.
      things = [files, history]
      # Save an API call by not looking for comments if there are none.
      # Also, when a Gist is created there are no comments sent back (duh)
      # Therefore we need to convert the attribute to an integer,
      # as it may be nil when returned.
      things << [comments] if @attributes["comments"].to_i > 0
      things.flatten.each do |thing|
        thing.gist = self
      end
    end
    
    def update_attributes(attributes={})
      url = self.class.singular_url(@attributes["id"])
      self.class.new(self.class.post(url, :body => attributes.to_json))
    end

    def user
      @user ||= User.new(@attributes["user"]) if @attributes["user"]
    end
    
    alias_method :owner, :user

    def history
      @history ||= [*@attributes["history"]].map do |history|
        Octopi::Gist::History.new(history)
      end
    end

    def files
      @files ||= [*@attributes["files"]].map do |name, attributes| 
        Octopi::Gist::GistFile.new(attributes.merge(:name => name))
      end
    end

    def comments
      @comments ||= self.class.collection("/gists/#{self.id}/comments", Gist::Comment)
    end
  end
end