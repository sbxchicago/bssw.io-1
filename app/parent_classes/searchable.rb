class SearchResult < MarkdownImport
  include AlgoliaSearch

  algoliasearch per_environment: true, sanitize: true, auto_index: false do
    # the list of attributes sent to Algolia's API
    attribute :name
    [:description, :short_bio, :long_bio, :author_list, :location, :organizers, :content].each do |facet|
      attribute facet do
        respond_to?(facet) ? self.send(facet) : nil
      end

      advancedSyntax true
    end

  end
end
