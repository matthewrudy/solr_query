module SolrQuery
  class << self
    # build a query for solr
    #
    #   SolrQuery.build(:keyword => "Feather duster")
    #   => "feather duster"
    #
    #   SolrQuery.build(:keyword => "clean", :organisation => [organisation1, organisation2])
    #   => "clean AND organisation:(275 OR 6534)"
    #
    #   SolrQuery.build(:colour => ["red", "pink"], :item_type => ["Toy", "Train"])
    #   => "colour:(red OR pink) AND item_type:(Toy OR Train)"
    # 
    # or you can specify a different magical key for keyword;
    #
    #   SolrQuery.build({:keyword => "old one", :new_keyword => "new one"}, :new_keyword)
    #   => "new one AND keyword:(old one)"
    # if you need to do range queries;
    # 
    #   SolrQuery.build(:salary => {:min => "010000", :max => "050000"})
    #   => "salary:([010000 TO 050000])"
    # 
    #   SolrQuery.build(:salary => "010000".."050000")
    #   => "salary:([010000 TO 050000])"
    # 
    #   SolrQuery.build(:surname => {:min => "jacobs")
    #   => "surname:([jacobs TO *])"
    def build(conditions = {}, keyword_key=:keyword)
      conditions = conditions.dup # let's not accidentally kill our original params
      query_parts = []
      keyword = conditions.delete(keyword_key) # keyword is magical
      if !blank?(keyword) # ie. !keyword.blank?
        query_parts << "#{solr_value(keyword, :downcase => true)}"
      end
    
      conditions.each do |field, value|
        unless value.nil?
          query_parts << "#{field}:(#{solr_value(value)})"
        end
      end
      
      if query_parts.empty?
        return ""
      else
        return query_parts.join(" AND ")
      end
    end
  
    def solr_value(object, opts={})
      downcase    = opts[:downcase]
      dont_escape = opts[:dont_escape]
      
      if object.is_a?(Array) # case when Array will break for has_manys
        if object.empty?
          string = "NIL" # an empty array should be equivalent to "don't match anything"
        else
          string = object.map do |element|
            solr_value(element, opts.merge(:dont_escape => true))
          end.join(" OR ")
          downcase = false # don't downcase the ORs
        end
      elsif object.is_a?(Hash) || object.is_a?(Range)
        return solr_range(object) # avoid escaping the *
      elsif defined?(ActiveRecord) && object.is_a?(ActiveRecord::Base)
        string = object.id.to_s
      elsif object.is_a?(String)
        if downcase && (bits = object.split(" OR ")) && bits.length > 1
          return "(#{solr_value(bits, opts)})"
        else
          string = object
        end
      else
        string = object.to_s
      end
      string.downcase!                    if downcase 
      string = escape_solr_string(string) unless dont_escape
      
      string
    end
    protected :solr_value
    
    def solr_range(object)
      min = max = nil
      if object.is_a?(Hash)
        min = object[:min]
        max = object[:max]
      else
        min = object.first
        max = object.last
      end
      min = solr_value(min) if min
      max = solr_value(max) if max
      
      min ||= "*"
      max ||= "*"
      
      return "[#{min} TO #{max}]"
    end
    protected :solr_range

    def escape_solr_string(string)
      string.gsub(SOLR_ESCAPE_REGEXP, "\\\\\\0").strip
    end
    protected :escape_solr_string
    
    def blank?(object) #:nodoc: quick rehash of rails' object.blank?
      if object.is_a?(String)
        object !~ /\S/
      else
        object.respond_to?(:empty?) ? object.empty? : !object
      end
    end
    protected :blank?
        
  end
  
  SOLR_ESCAPE_CHARACTERS = %w" \\ + - ! ( ) : ; ^ [ ] { } ~ * ? "
  SOLR_ESCAPE_REGEXP = Regexp.new(SOLR_ESCAPE_CHARACTERS.map{|char| Regexp.escape(char)}.join("|"))
end
