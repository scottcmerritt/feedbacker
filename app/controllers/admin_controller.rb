class AdminController < ApplicationController
	include Feedbacker::FeedbackerAdminController
	
	def debug

		@json = []
		if params[:add]
			val = [{:table=>"source_authors", :count=>2216}, {:table=>"imports", :count=>35}, {:table=>"content_topics", :count=>0}]
			val = [{:table=>"voter_audits", :count=>10}, {:table=>"summary_sources", :count=>103}, {:table=>"users", :count=>11}, {:table=>"vote_audits", :count=>0}] #  {:table=>"summary_items_removed", :count=>0}, 
			@json = val.to_json
			#@row = DebugLog.create(value:Marshal.dump(val.to_json))
			@row = DebugLog.create(value:val.to_json.to_s)

		end
		@log = DebugLog.all.order("created_at DESC")

	end
end