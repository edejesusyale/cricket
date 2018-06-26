# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  self.default_processor_chain += [:add_custom_data_to_query]
  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]
  include Hydra::AccessControlsEnforcement

  ##
  # @example Adding a new step to the processor chain


  #tokenizing to add the booleans
    def add_custom_data_to_query(solr_parameters)
      #puts("TEST!!: "+ blacklight_params.to_s)
      #blacklight_params["search_field"] = 'oid'

      #the unless' are necessary for bookmarks to work
       blacklight_params["q"] = tokObjSearch(blacklight_params["q"]) unless !blacklight_params["q"].is_a? String || !has_search_parameters?
       puts "LOVE :" +blacklight_params["q"] unless !blacklight_params["q"].is_a? String
       solr_parameters[:custom] = blacklight_params[:user_value]


    end

  def tokObjSearch (params)

    @temp_str = params
    return nil unless @temp_str != ''
    delimiters = [' ','/' , ',' , '\n']

    #tokens the string by each delimiter above
    delimiters.each do |x|
      @tok_str = ''
      @temp_str = @temp_str.split( x )
      #puts("SPLIT: #{@temp_str}")
      @tok_str += (@temp_str.pop) +  '~'  until @temp_str.size==0
      puts "X: #{x} | tokstr: #{@tok_str}"
      @temp_str = @tok_str
    end

    #rebuilds the string with the Boolean OR logic
    @tok_str = ''
    @temp_str = @temp_str.split( '~' )
    puts(@temp_str)
    @temp_str = @temp_str.uniq
    until @temp_str.size==0
      @tok_str += @temp_str.size != 0? ' OR ' : ' ' unless @tok_str == ''
      @tok_str += @temp_str.pop
    end
    return @tok_str

  end


end
