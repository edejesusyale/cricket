# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller

  include Hydra::Catalog
  # This filter applies the hydra access controls
  #before_action :enforce_show_permissions, only: :show
  Hydra::SearchBuilder.default_processor_chain -= [:add_access_controls_to_solr_params]
  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      qt: 'search',
      rows: 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_tesim'
    config.index.display_type_field = 'has_model_ssim'


    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _tsimed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    config.add_facet_field solr_name( 'viewopt_ssi'),label: 'test'
    config.add_facet_field solr_name('id', :facetable), label: 'Format'
    config.add_facet_field solr_name('pub_date', :facetable), label: 'Publication Year'
    config.add_facet_field solr_name('subject_topic', :facetable), label: 'Topic', limit: 20
    config.add_facet_field solr_name('language', :facetable), label: 'Language', limit: true
    config.add_facet_field solr_name('lc1_letter', :facetable), label: 'Call Number'
    config.add_facet_field solr_name('subject_geo', :facetable), label: 'Region'
    config.add_facet_field solr_name('subject_era', :facetable), label: 'Era'

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'oid_isi', label: 'oid_isi'
    config.add_index_field 'id', label: 'id'
    config.add_index_field 'viewopt_ssi', label: 'Viewopt'
    config.add_index_field 'timestamp' , label: 'timestamp'
    config.add_index_field 'state_ssi' , label: 'state_ssi'
    config.add_index_field 'active_fedora_model_ssim' , label: 'active_fedora_model_ssim'
    #config.add_index_field
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    #
    config.add_show_field 'oid_isi', label: 'oid_isi'
    config.add_show_field 'id', label: 'id'
    config.add_show_field 'viewopt_ssi', label: 'Viewopt'
    config.add_show_field 'timestamp' , label: 'timestamp'
    config.add_show_field 'state_ssi' , label: 'state_ssi'
    config.add_show_field 'active_fedora_model_ssim' , label: 'active_fedora_model_ssim'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.



    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    #
    config.add_search_field 'all_fields', label: 'All Fields'

    config.add_search_field('oid_isi') do |field|
      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_parameters = {
          qf: 'oid_isi',
          pf: 'oid_isi'
      }
    end

    config.add_search_field('id') do |field|
      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_parameters = {
          qf: 'id',
          pf: 'id'
      }
    end


    config.add_search_field('title') do |field|
      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
          qf: '$title_qf',
          pf: '$title_pf'
      }
    end


    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'oid_isi asc, title_tesi asc', label: 'oid_isi'
    config.add_sort_field 'id asc, title_tesi asc', label: 'id'
    config.add_sort_field 'score desc, pub_date_dtsi desc, title_tesi asc', label: 'relevance'


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end



end
