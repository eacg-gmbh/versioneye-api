class SearchResults

  attr_accessor :lang, :prod_key
  attr_accessor :query, :group_id, :languages, :paging, :entries
  attr_accessor :current_page, :per_page, :total_entries, :total_pages

  def initialize args
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

end
