module Feedbacker
  module ToggleLinkHelper
    def togglelink_for(label,href, options=nil) # {div_class:"px-2",target: nil}
      ToggleLink.new(self, label, href, options).html
    end


    class ToggleLink
      def initialize(view, label, href, options)
        @view, @label, @href, @options = view, label, href, options
        @color = options[:count_color] || "secondary"
        @count_text_color = options[:count_text_color] || "dark"
        @count_label = options[:count_label]
        @count = options[:count]
        @count_css = options[:count_css] || "ml-1"
        @link_color = options[:link_color]
        @expanded = options[:expanded] == false ? false : true
        @uid = SecureRandom.hex(6)
        @css_group = options[:css_group]
      end

      def html
        #content = safe_join([indicators, slides, controls])
        #content_tag(:div, content, id: uid, class: 'carousel slide')

        content = safe_join([make_link])
        if @options[:no_wrap]
          content
        else
          content_tag(:div, content, id: uid, class: "#{@options[:div_class]}")
        end
      end

      private

      attr_accessor :view, :label, :href, :options, :uid
      delegate :link_to, :content_tag, :image_tag, :safe_join, to: :view

      def make_badge
        content_tag(:span, "#{@count}#{@count_label.nil? ? "" : " #{@count_label}"}",class: "#{@count_css} badge badge-#{@color}") unless @count.nil?
      end

      def make_link
        label_content = safe_join([content_tag(:span,@label,class: "ms-1 ml-1"),make_badge])
        content = safe_join([make_collapsed_icon,make_expanded_icon,label_content])
        extra_class = "#{@css_group} d-flex align-items-center #{@link_color}"
        options = {
          class: "text-toggle nodec #{extra_class}",
          aria: {expanded: @expanded},
          data: {  
            # bootstrap 4
            target: @options[:target],
            toggle: "collapse",
            # bootstrap 5
            "bs-target": @options[:target],
            "bs-toggle": "collapse"
          }
        }

        link_to content, @href, options #, class: "p-1 text-#{@text_color}"
        #content_tag(:a,content,{href: @href, class: "p-1"})
      end

      def make_collapsed_icon
        content = content_tag(:i,'',class: "fas fa-angle-right expandIcon")
        content_tag(:span,content,class: "text-collapsed")
      end

      def make_expanded_icon
        content = content_tag(:i,'',class: "fas fa-angle-down expandIcon")
        content_tag(:span,content,class: "text-expanded")
      end

      def indicators
        items = images.count.times.map { |index| indicator_tag(index) }
        content_tag(:ol, safe_join(items), class: 'carousel-indicators')
      end

    end
  end
end