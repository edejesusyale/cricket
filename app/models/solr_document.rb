# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document


  alias first_value first
  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)


  def archival?
    self[:viewopt_ssi] == 'archival' ||  self[:viewopt_ssi] == 'archivalDigitized'
  end


  def model
    self[:active_fedora_model_ssim].first
  end

  def title
    self[:title_tsim].first
  end

  def viewopt
    self[:viewopt_ssi]
  end

  def oid
    self[:oid_isi]
  end

  def parent_oid
    self[:parentoid_isi]
  end

  def pdf_link( request )
    "#{request.protocol}#{request.host}:#{request.server_port}/pdf/generate_pdf?oid=#{self.oid}"
  end


  def id_number
    self[:id].gsub('digcoll:', '')
  end

  def parent_id
    if !self[:is_member_of_ssim].blank?
      self[:is_member_of_ssim].first.remove('info:fedora/')
    else
      nil
    end
  end


  def aeon_request_link
    self.class.load_config
    "#{@@aeon_request_url_prefix}&#{aeon_request_variables}"
  end


  def datastream_info
    info = {}
    object_profile = JSON.parse(self[:object_profile_ssm].first)
    if object_profile
      datastreams = object_profile['datastreams']
      if datastreams
        datastreams.each { |key,value|
          info[key] = value
        }
      end
    end
    info
  end


  def datastream_size? datastream_id
    ds_info = datastream_info[datastream_id]
    ds_size = 0
    if ds_info
      ds_size = ds_info['dsSize']
    end
    ds_size.to_i
  end

  def stream_exists? datastream_id
    datastream_size?(datastream_id) > 0
  end


  private

  @@config_loaded = false
  def self.load_config
    if !@@config_loaded
      @@config_loaded = true
      yaml = YAML.load_file(Rails.root.join('config/app_config.yml'))[Rails.env]
      @@aeon_request_url_prefix = yaml.fetch('aeon_request_url_prefix','https://aeon-2-dev.its.yale.edu/aeon.dll?Action=10&Form=20&Value=GenericRequestKissinger')
    end
  end

  def aeon_request_variables
    vars = {CallNumber: first('call_number_ssim'),
            ItemTitle: first('digital_collection_ssim'),
            ItemIssue: first('series_tsim'),
            ItemEdition: extract_breadcrumb,
            ItemNumber: first('loc_rec_num_ssim'),
            ItemInfo2: self['id'],
            EADNumber: "http://hdl.handle.net/10079/digcoll/#{id_number}"
    }
    vars.delete_if{ |k, v| v.nil? }.to_query
  end

  def extract_breadcrumb
    breadcrumbs = "#{self['breadcrumbs_ssm']}"
    if breadcrumbs
      breadcrumbs.delete('[]').delete('\\')[1..-2]
    else
      ''
    end
  end

end