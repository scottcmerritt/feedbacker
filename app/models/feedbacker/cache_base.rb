module Feedbacker
	class CacheBase

		def self.increment! rkey, amount: 1
			$redis.incrby rkey, amount
		end

		def self.integer_value rkey
			$redis.get(rkey).to_i
		end

		def self.time_to_live rkey
			$redis.ttl rkey
		end

		def self.exists? hashkey
			return $redis.exists? hashkey
		end

		def self.remove_key rkey
			$redis.del rkey
		end


		# changes (usually extending) the expiration, or adds an expiration
		def self.change_expiration! hashkey, seconds
			$redis.expire hashkey, seconds
		end

		def self.add_list_item rkey, id
			unless $redis.sismember rkey, id
				$redis.sadd rkey, id
			end
		end

		def self.list_count rkey
			$redis.scard rkey
		end

		# spop hash (a number), removes a random number from a list
		# srem hahs [members]
		def self.remove_list_item rkey, id
			$redis.srem rkey, id
		end

		def self.add_list_object rkey, obj, cache_expiration: nil, logger: nil
			hashkey = CacheBase.set_unique_obj obj, logger: logger, cache_expiration: cache_expiration
			$redis.sadd rkey, hashkey unless hashkey.nil? || $redis.sismember(rkey,hashkey)
		end

		def self.destroy_list_object! rkey, hashkey
			CacheBase.remove_list_item rkey, hashkey
			CacheBase.remove_key hashkey
		end
		def self.remove_list_object rkey, obj
			obj_as_string = Marshal.dump(obj)
			hashkey = Digest::SHA256.hexdigest obj_as_string
		
			CacheBase.destroy_list_object! rkey, hashkey unless hashkey.nil?
			return hashkey
		end
		
		def self.get_list_objects rkey, load_objects: false, with_keys: false
			if load_objects
				data = []
				$redis.smembers(rkey).each do |hashkey|
					data.push({key: hashkey, obj: CacheBase.get_obj(hashkey)}) if with_keys
					data.push CacheBase.get_obj(hashkey) unless with_keys
				end
			else
				data = $redis.smembers(rkey)
			end
			return data
		end

		# clear list AND objects within it
		def self.destroy_list! rkey
			items = CacheBase.get_list_items(rkey)
			items.each do |hashkey|
				CacheBase.destroy_list_object! rkey, hashkey
			end
		end


		# gets a list of ids
		def self.get_list_items rkey, indexed=false, as_integer=false
			data = $redis.smembers(rkey)
			if indexed
				idx = {}
				data.each do |list_item_id|
					if as_integer
						idx[list_item_id.to_i]=true
					else
						idx[list_item_id]=true
					end
				end
				return idx
			else
				if as_integer
					return data.collect { |v| v.to_i } 
				else
					return data
				end
			end
		end

		def self.get_obj hashkey, logger=nil
			#hashkey = "#{Settings::DEFAULT_CACHE_PREFIX}#{hashkey}"

			raw_redis = $redis.get(hashkey)
			logger.debug "get cache, hashkey: #{hashkey}: #{raw_redis.length}" unless raw_redis.nil? || logger.nil?

			unless raw_redis.nil?
				items = Marshal.load(raw_redis)
				if items.nil?
					logger.debug "NOT ITEM FOUND, get cache, hashkey: #{hashkey}" unless logger.nil?
				else
					logger.debug "get cache, hashkey: #{hashkey}: #{items.length}" unless logger.nil?
				end
				return items
			else
				logger.debug "raw_redis is NULL for: #{hashkey}" unless logger.nil?
			end
			return nil
		end

		def self.get_bool hashkey, logger=nil
			#hashkey = "#{Settings::DEFAULT_CACHE_PREFIX}#{hashkey}"

			raw_redis = $redis.get(hashkey)
			return raw_redis == '1' ? true : (raw_redis == '0' ? false : nil)
		end

		def self.set_bool hashkey, val,logger=nil, cache_expiration=60000
			#hashkey = "#{Settings::DEFAULT_CACHE_PREFIX}#{hashkey}"
			obj_as_string = val == true ? '1' : '0' #Marshal.dump(objects)
			$redis.set(hashkey,obj_as_string,ex:cache_expiration)
		end

		def self.set_obj hashkey, objects,logger=nil, cache_expiration=60000
			#hashkey = "#{Settings::DEFAULT_CACHE_PREFIX}#{hashkey}"

			logger.debug "set cache, hashkey: #{hashkey}: #{objects.length}" unless logger.nil?
			obj_as_string = Marshal.dump(objects)
			
			#$redis.set(hashkey,obj_as_string,{:ex=>cache_expiration})
			$redis.set(hashkey,obj_as_string,ex: cache_expiration)
		end

		# takes the objects, marshals them into a string, adds them to redis and returns the unique identifier
		def self.set_unique_obj objects, logger: nil, cache_expiration:nil

			obj_as_string = Marshal.dump(objects)
			hashkey = Digest::SHA256.hexdigest obj_as_string
			if CacheBase.exists? hashkey
				return nil
			else
				$redis.set(hashkey,obj_as_string,ex:cache_expiration) # {:ex=>cache_expiration})
				return hashkey
			end
		end

		def self.get_by_params prefix, params, logger = nil
			hash_string = params.to_s
			hashkey = Digest::SHA256.hexdigest(hash_string)
			cache_key = prefix + hashkey

			return Cache.get_obj(cache_key, logger)
		end

		def self.cache_by_params prefix, params, data, logger = nil, cache_expiration=120
			#cache_key = BCrypt::Password.new(params.to_s)		
			#BCrypt::Password.new(self.password) == supplied_password

			hash_string = params.to_s #{:user_id=>user_id,:options=>options.except(:logger,:refresh_cache)}.to_json.to_s
			hashkey = Digest::SHA256.hexdigest(hash_string)
			cache_key = prefix + hashkey
			Cache.set_obj cache_key, data, logger, cache_expiration
			return data
		end

	end
end