class CommentsDto 

  attr_accessor :comments, :paging

  def initialize args
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

end 
