module Feedbacker
class DataLog < ApplicationRecord
	self.table_name = "data_logs"

	def load_value
		begin
			return Marshal.load(self.value)
		rescue Exception => ex
			Rails.logger.debug "ERROR::: inside load_value1 #{ex}"
			decoded = ActiveRecord::Base.connection.unescape_bytea(self.value)
			begin
				return Marshal.load(decoded)
			rescue Exception => ex
				Rails.logger.debug "ERROR::: inside load_value2 #{ex}"
			end
		end
	end

	def self.add domain: "log", key:, value:

	end

	def self.db_rows start: 120
		datefmt = "%b %e, %Y %l:%M %p" #{}"%b %Y, %e %y"
		 rows = DataLog.where(domain:"db",key:"rows").order("created_at DESC")
		 rows = rows.where("created_at > ?",start.days.ago)
		 hash_rows = []
		 rows.each do |row|
		 	ca =  row.created_at #.strftime(datefmt) #row.created_at.strftime(datefmt)
		 	begin
		 		hash_rows.push({data:JSON.parse(row.load_value),created_at:ca,note:row.note})
		 	rescue Exception => ex
			 	Rails.logger.debug "Error::: db_rows: #{ex}"
			end
		 end
		 hash_rows
	end

	def self.db_rows_fmt start: 120, table_filters: nil
		table_filters = nil if !table_filters.nil? && table_filters.length == 0
		dates = {}
		tables = {}
		DataLog.db_rows(start:start).each do |snapshot|
			datekey = snapshot[:created_at]
			dates[datekey] = {}
			unless snapshot.nil? || snapshot[:data].nil?
			snapshot[:data].each do |row|
				if table_filters.nil? || (table_filters.include?(row["table"]) || table_filters.any?{|s| s[row["table"]]})
					tables[row["table"]] = {} unless tables.key?(row["table"])
					tables[row["table"]][datekey] = row["count"]
				end
			end
			end

		end

		result = []
		tables.each do |k,v|
			result.push({"name":k,"data":v})
		end
		result
	end



	def self.mock_data user_id:nil
		DataLog.all.order("id DESC").offset(6).destroy_all

		(2..60).step(2) do |num|
#		(1...20).each do |num|

			date_ago = (num).days.ago


			dt = "WHERE (created_at < '#{date_ago}')"
			#ActiveRecord::Base.connection.execute("select count(*) from #{tbl} #{dt}")[0]["count"] %>

			rows = []
			ActiveRecord::Base.connection.tables.each do |t|
				begin
					res_count = ActiveRecord::Base.connection.execute("select count(*) from #{t} #{dt}")[0]["count"]
				rescue
					res_count = ActiveRecord::Base.connection.execute("select count(*) from #{t}")[0]["count"]
				end
			 	rows.push({"table"=>t, "count"=>res_count})
			end
			rows = rows.sort_by{|row| -row["count"]}

			DataLog.create(created_at:date_ago,note:"cleaning db",created_by:user_id,domain:"db",key:"rows", value:Marshal.dump(rows.to_json))
		end
	end
end
end