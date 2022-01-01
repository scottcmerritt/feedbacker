module Feedbacker
module Ui
class UserColor

	def initialize params = {}
		@room = params[:room] || nil
		@users = params[:users] || []

		@colors_indexed = nil

		@color_set = nil
		@min_gradient_size = 10
	end

	def color_gradient gradient_size = 100
		@color_set = self.rainbow_set if @color_set.nil?
		@gradient = Gradient.new(:steps=>gradient_size,:colors=>@color_set).hex
	end

	def random_gradient suggested_size = 0
		Gradient.new(:steps=>[@min_gradient_size,suggested_size].max,:colors=>self.random_color_set).hex.shuffle
	end

	def gradients gradient_size = 10
		@gradients = []
		@gradients.push Gradient.new(:steps=>gradient_size,:colors=>self.rainbow_set).hex #.shuffle
		self.color_sets.each do |color_set|
			@gradients.push Gradient.new(:steps=>gradient_size,:colors=>color_set).hex #.shuffle
		end
		return @gradients
	end

	def clear_colors
		Feedbacker::Cache.remove_key self.hashkey
	end
	
	def user_colors
		self.load_user_colors if @colors_indexed.nil?
		return @colors_indexed
	end

	def hashkey
		hashkey = !@room.nil? ? "room::#{@room.id}::" : ""
	    hashkey+= "user_colors"
	    return hashkey
	end

	def random_color_set
		@color_set = self.color_sets.sample(1).first
	end

	def load_user_colors
	    @colors_indexed = Feedbacker::Cache.get_obj self.hashkey
	    @colors_indexed = {} if @colors_indexed.nil?

	    if @colors_indexed == {}
		    @gradient = self.random_gradient @users.length

		    @users.each_with_index do |user,index|
		      @colors_indexed[user.id] = @gradient[index]
		    end

		    Feedbacker::Cache.set_obj self.hashkey, @colors_indexed, nil, nil #logger=nil, Feedbacker::cache_expiration=60000
		end
	end

	def get_color user
		user_id = user.respond_to?(:id) ? user.id : user

		return @colors_indexed[user_id] if !@colors_indexed.nil? && @colors_indexed.has_key?(user_id)

	    @colors_indexed = Feedbacker::Cache.get_obj self.hashkey
	    if @colors_indexed.nil?
	    	# in this case, we can get a new color and add it to the list, and reFeedbacker::cache

	    	return nil #"#28a745" #{}"#e83e8c" #nil
	    else
	    	if @colors_indexed.has_key?(user_id)
	    		return @colors_indexed[user_id]
	    	else
	    		return self.add_color_for user
	    	end
	    end
	end

	def add_color_for user, gradient_size = 100
		user_id = user.respond_to?(:id) ? user.id : user

		color_set = self.rainbow_set

		@gradient = Gradient.new(:steps=>gradient_size,:colors=>color_set).hex.shuffle
		attempts = 0

		unique_not_found = true

		@new_color = "#000000"

		while unique_not_found && (attempts < gradient_size) do

			unless @colors_indexed.values.include?(@gradient[attempts])
				unique_not_found = false
				@new_color = @gradient[attempts]
			end

			attempts+=1
		end
		@colors_indexed[user_id] = @new_color #@gradient[0]
		Feedbacker::Cache.set_obj self.hashkey, @colors_indexed, nil, nil

		#TODO: check if @colors_indexed has a value of @gradient[0]

		return @colors_indexed[user_id] #@colors_indexed.has_key?(user_id) ?  # ?  : "#28a745"

	end
	def color_sets
		[
	      ["#20c997","#007bff","#28a745","#e83e8c"], # greenish, and blue
	      ["#007bff","#fd7e14","#6610f2"], # brow, blue, purple
	      ["#e83e8c","#007bff"], # pink to blue
	      ["#e83e8c","#ff9d0a","#28a745","#007bff"], #pink,green,blue
	      ["#007bff","#28a745","#e83e8c"] # blue, green, pink
		]
	end

	def rainbow_set
		["#ff0a0a","#ff9d0a","#ffd80a","#349109","#05bdae","#e9e9e9","#7109c4","#c4098f","#c40909"]
	end
end

end
end