module Feedbacker
	class Stats
		# returns the array of service tier hashes
		# TODO: gather upgrade options from used plugins in a more extensible way
		def self.service_upgrades
			defined?(Newsify) && Newsify.respond_to?(:service_upgrades) ? Newsify.service_upgrades : []
		end

		def self.database_info
			info = {
				prices: {
					intro: {name:"Free",rows:10000,price:"$0"},
					upgrades: Stats.service_upgrades,
				},
				adapter: ActiveRecord::Base.connection.instance_values["config"][:adapter], # what type of database, etc...
				rows: {used:nil,per_table:nil},
				tables: {hidden: ["schema_migrations","ar_internal_metadata"]},
				error: nil
			}
			

	        begin
	        	db_adapt = ActiveRecord::Base.connection.instance_values["config"][:adapter] # ActiveRecord::Base.configurations[Rails.env]['adapter']
	        	info[:rows][:used] = 0 #@rows_per_table.each.sum{|k,v| v["count"]}
                if db_adapt == "sqlite3"
                	info[:rows][:per_table] = ActiveRecord::Base.connection.tables.map { |t| {"table"=>t, "count"=>ActiveRecord::Base.connection.execute("select count(*) as 'count' from #{t}")[0]["count"]} } #.sort_by{|row| -row["count"]}
              
		            info[:rows][:per_table].each do |row|
		              info[:rows][:used]+=row["count"].to_i unless row.nil?
		            end
                else
	            	info[:rows][:per_table] = ActiveRecord::Base.connection.tables.map { |t| {"table"=>t, "count"=>ActiveRecord::Base.connection.execute("select count(*) from #{t}")[0]["count"]} }.sort_by{|row| -row["count"]}
	            
					info[:rows][:per_table].each do |row|
					  info[:rows][:used]+=row["count"] unless row.nil?
					end
				end
	          
	        	#@hidden_tables = ["schema_migrations","ar_internal_metadata"]
	        rescue => err
	          #@db_error = err
	          info[:error] = err
	        end
	        info
		end
	end

end
