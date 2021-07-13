module Feedbacker
  module UiHelper

    def feedback_h content
      tag.h3 content, class: "bg-primary text-light px-2 py-1 my-1"

    end

    def feedbacker_tabs tabs:
      unless tabs.nil?
        content = (tabs.map{|row| [row.tab_key,row.content]}).to_h
        render(partial: "menu/tabs",locals: {tabs: tabs,show_content_toggle: false,link_wrap_css:"nav-item-tiny",link_css:"rounded-0 fsz7",css_group:"fsz8"}) + render(partial: "menu/tabs_content",locals: {:tabs=>tabs,:content=>content,id:"yourResultsWrap",wrap_css:""})
      end
    end

    def feedbacker_menu tabs:, controller: nil, action: nil, style: "pill", justified: true, horiz: true, color: "light", css:nil, nav_css: nil

      wrap_style = style == "pill" ? "nav-pills" : ""
      wrap_style+=" nav-justified" if justified
      wrap_style+=" bg-light" if color == "light"
      wrap_style+=" bg-dark" if color == "dark"

      res = render(partial: "menu/menu",locals: {tabs:tabs,controller:controller,action:action,wrap_style:wrap_style,css:nav_css})
      css.nil? ? res : tag.div(res, class: css)
    end

    def feedbacker_list data #title:nil,rows:, paging: true, page: 1, page_size:2, labels:{}, with_borders: true, prepend_paths: nil, attach_paths: nil, attach_methods: nil, prepend_methods: nil, ignore_columns: nil, filtered: nil
      data = data.merge({:view=>"list"})
      ignore_cols = ["user_id","details","createdby","is_public","is_global","approved","approved_at","approved_by","removed","removed_by","removed_at"]
      data = data.merge({:ignore_columns=> ( data[:ignore_columns].nil? ? ignore_cols : data[:ignore_columns]+=ignore_cols ) })
      feedbacker_rows(**data) #view: "list", rows: rows
    end

    def feedbacker_table data #title:nil,rows:, paging: true, page: 1, page_size:2, labels:{}, with_borders: true, prepend_paths: nil, attach_paths: nil, attach_methods: nil, prepend_methods: nil, ignore_columns: nil, filtered: nil
      data = data.merge({:view=>"table"})
      ignore_cols = ["user_id","details","createdby","is_public","is_global","approved","approved_at","approved_by","removed","removed_by","removed_at"]
      data = data.merge({:ignore_columns=> ( data[:ignore_columns].nil? ? ignore_cols : data[:ignore_columns]+=ignore_cols ) })

      feedbacker_rows(**data)
    end

    def feedbacker_rows view: "table", title:nil,rows:, paging: true, page: 1, page_size:2, labels:{}, with_borders: true, prepend_paths: nil, attach_paths: nil, attach_methods: nil, prepend_methods: nil, ignore_columns: nil, filtered: nil
      
      # used to accomodate filters by recency, etc...
      default_filtered = {:comments => false}

      filtered = filtered.nil? ? default_filtered : default_filtered.merge(filtered)

      default_labels = {:created_at=>"Added",:updated_at=>"Updated",:user_id=>"User"}
      all_labels = default_labels.merge(labels)


      #view_path_data = {:title=>"Brainstorm",:data=>{:path=>"brainstorming_path",:prompt=>:post_id}}
      #resolve_path_data = {:title=>"Resolve prompt",:data=>{:path=>"admin_ideas_do_action_path",:do=>"resolve_prompt",:oid=>:id,:otype=>:otype_guessed}}

      #attach_paths = [resolve_path_data,view_path_data]

      # comment_threads.count

      # these are methods run to generate data (or links)
      if prepend_methods.nil?

      end
       
      # these are methods run (added to the end of the table)
      if attach_methods.nil?
        #[:to_i, :comments, :count]

        attach_methods = []
        cmt_lbl = "All Comments"
        if filtered[:comments] == true
          #attach_methods.push ["Recent comments",[:comment_count]]
          all_labels = all_labels.merge({:comment_count=>"Recent Comments"})
        else
          cmt_lbl = "Comments"
          # NOTE: alternatively, we could use the comment_count if it exists already via a JOIN
          ignore_columns = [] if ignore_columns.nil?
          ignore_columns.push("comment_count")
        end
        attach_methods.push [cmt_lbl,[:comment_threads,:count]]
        
      end

      klass_name = rows[0].class.name.downcase
      
      if prepend_paths.nil?
        show_path_data = {:title_sym=>:title,:data=>{:path=>"#{klass_name}_path",:id=>:id}}
        prepend_paths = [show_path_data]

        ignore_columns = [] if ignore_columns.nil?
        ignore_columns.push("title")
        ignore_columns.push("id")
      end

      if attach_paths.nil?
        
        edit_path_data = {:title=>"Edit",:data=>{:path=>"edit_#{klass_name}_path",:id=>:id}}
        destroy_path_data = {:title=>"Delete",:data=>{:path=>"#{klass_name}_path",:id=>:id},:method=>:delete}
        attach_paths = [edit_path_data,destroy_path_data]
      end

      rows = rows.page(page).per(page_size) if paging
      local_data = {
                    title:title,rows: rows, labels: all_labels, with_borders:with_borders,
                    prepend_paths: prepend_paths, attach_paths: attach_paths, prepend_methods: prepend_methods, attach_methods: attach_methods,
                    ignore_columns: ignore_columns, time_ago_columns: ["created_at","updated_at"]
                  }

      render partial:"feedbacker/ui/#{view == "list" ? "list" : "auto_table"}", locals: local_data #{data: rows,title: title}
    end


  end

end