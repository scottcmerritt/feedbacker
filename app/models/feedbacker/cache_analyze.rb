module Feedbacker
class CacheAnalyze

	# goal: get notion of frequency of cache keys

	# 1) scan keys, in groups of 1000

	# 2) build frequency of X (i.e. 5) char prefixes so "my_super_cache_key" -> "my_su"

	# 3) build hash of frequencies, clear low hits

	def initialize opts = {}
		@matching = opts[:matching] || nil

		@matching = "*"+@matching if opts[:wildcard] && !@matching.nil?

		@key_hits = {}
		@prefix_len = opts[:prefix_len] || 10
		@prefix_len = @prefix_len.to_i
		@prefix_len2 = @prefix_len*3
	end

	def run
		scan_all
		clear_low_hits!
	end

	# this works:  $redis.scan_each(:match => "cache*") do |key|
	def run_old
		10000.times.each do |num|
			scan_res = $redis.scan(num*10)
			next_scan = scan_res[0]
			some_keys = scan_res[1]
			some_keys.each do |sk|
				prefix = sk[0..key_len]
				@key_hits[prefix] = 0 unless @key_hits.key?(prefix)
				@key_hits[prefix] = @key_hits[prefix] + 1
			end
			clear_low_hits! if num % 100 == 0
		end
	end


	def self.redis_free_up_space! max_rows: 1000
		removed = []
		CacheAnalyze.bad_keys(max_rows:max_rows).each do |key|
			Cache.remove_key key
			removed.push key
		end
		removed
	end

	# *<Tag*
	def self.bad_keys matching: "*#<*", max_rows: 500


		iterator = nil
		keys = []


		while iterator != '0'
			if matching.nil?
				iterator, list = $redis.scan(iterator || 0, count: 1000)
			else
				@prefix_len = @prefix_len2
				iterator, list = $redis.scan(iterator || 0, :match=> matching) #, count: 1000) #, match: @matching)
			end

		list.each do |new_key|
			keys.push new_key
			return keys if keys.length >= max_rows
		end

#		  keys += list.map { |l| l.split(':') }
#		  puts "Found another #{list.length} keys, iterator at #{iterator}"
		end

		keys

	end

	def self.some_keys per_page: 100, max_rows: 100
		iterator = nil
		per_page = max_rows if per_page > max_rows

		res = {}
		while iterator != '0'
			iterator, list = $redis.scan(iterator || 0, count: per_page)
			list.each do |key|
				res[key] = Cache.time_to_live key
			end
			return res if res.length >= max_rows
		end

		res
	end

	def scan_all max_rows: 2000
		iterator = nil
		keys = []


		cnt = 0
		while iterator != '0'
			if @matching.nil?
				iterator, list = $redis.scan(iterator || 0, count: 1000)
			else
				@prefix_len = @prefix_len2
				iterator, list = $redis.scan(iterator || 0, :match=> @matching) #, count: 1000) #, match: @matching)
			end

		list.each do |new_key|
			prefix = new_key[0..@prefix_len]
			@key_hits[prefix] = 0 unless @key_hits.key?(prefix)
			@key_hits[prefix] = @key_hits[prefix] + 1
			cnt+=1
			#keys.push new_key
			return keys if cnt >= max_rows
		end

#		  keys += list.map { |l| l.split(':') }
#		  puts "Found another #{list.length} keys, iterator at #{iterator}"
		end

		keys
	end

	def scan_some

	end

	def clear_low_hits! min_thresh: 2
		@key_hits.each do |k,v|
			@key_hits.delete(k) if v < min_thresh
		end
	end

	def results
		@key_hits.sort_by{|k,v| -v}
	end

	def self.redis_stats
		{
			keys_count: $redis.info["db0"],
			used_memory: $redis.info["used_memory_human"],
			peak_memory: $redis.info["used_memory_peak_human"],
			uptime_in_days: $redis.info["uptime_in_days"],

			hits: $redis.info["keyspace_hits"].to_i,
			misses:$redis.info["keyspace_misses"].to_i,
			expired_keys: $redis.info["expired_keys"].to_i,
			db_size: $redis.dbsize,
			maxmemory_policy: $redis.info["maxmemory_policy"]
		}
	end

end
end