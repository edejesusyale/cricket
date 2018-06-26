class Book < ActiveFedora::Base
  property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_searchable
  end
  property :author, predicate: ::RDF::Vocab::DC.creator, multiple: false do |index|
    index.as :stored_searchable
  end
  property :oid_isi, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
    index.as :stored_searchable
    end
end
