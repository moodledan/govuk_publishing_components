module GovukPublishingComponents
  module Presenters
    class BreadcrumbSelector
      def self.call(*args)
        new(*args).output
      end

      attr_reader :content_item, :request, :prioritise_taxon_breadcrumbs

      def initialize(content_item, request, prioritise_taxon_breadcrumbs)
        @content_item = content_item
        @request = request
        @prioritise_taxon_breadcrumbs = prioritise_taxon_breadcrumbs
      end

      def content_item_navigation
        @content_item_navigation ||= ContextualNavigation.new(content_item, request)
      end

      def parent_item_navigation
        @parent_item_navigation ||= ContextualNavigation.new(parent_item, request)
      end

      def parent_item
        @parent_item ||= Services.content_store.content_item(content_item_navigation.parent_api_path)
      rescue GdsApi::ContentStore::ItemNotFound
        # Do nothing
      end

      def parent_item_options
        @parent_item_options ||= options(parent_item_navigation)
      end

      def content_item_options
        @content_item_options ||= options(content_item_navigation)
      end

      def parent_breadcrumbs
        breadcrumbs = [parent_item_options[:breadcrumbs]].flatten # to ensure breadcrumbs always an array
        breadcrumbs.last[:is_page_parent] = false
        breadcrumbs << {
          title: parent_item["title"],
          url: parent_item["base_path"],
          is_page_parent: true,
        }
      end

      def parent_is_step_by_step?
        parent_item_options[:step_by_step]
      end

      def output
        return content_item_options unless content_item_navigation.html_publication_with_parent?
        return parent_item_options if parent_item_navigation.priority_breadcrumbs

        {
          step_by_step: parent_is_step_by_step?,
          breadcrumbs: parent_is_step_by_step? ? parent_breadcrumbs.first : parent_breadcrumbs,
        }
      end

      def options(navigation)
        if navigation.content_tagged_to_a_finder?
          {
            step_by_step: false,
            breadcrumbs: navigation.finder_breadcrumbs,
          }
        elsif navigation.content_tagged_to_current_step_by_step?
          {
            step_by_step: true,
            breadcrumbs: navigation.step_nav_helper.header,
          }
        elsif navigation.priority_breadcrumbs
          {
            step_by_step: true,
            breadcrumbs: navigation.priority_breadcrumbs,
          }
        elsif navigation.content_is_tagged_to_a_live_taxon? && prioritise_taxon_breadcrumbs
          {
            step_by_step: false,
            breadcrumbs: navigation.taxon_breadcrumbs,
          }
        elsif navigation.content_tagged_to_mainstream_browse_pages?
          {
            step_by_step: false,
            breadcrumbs: navigation.breadcrumbs,
          }
        elsif navigation.content_has_curated_related_items?
          {
            step_by_step: false,
            breadcrumbs: navigation.breadcrumbs,
          }
        elsif navigation.use_taxon_breadcrumbs?
          {
            step_by_step: false,
            breadcrumbs: navigation.taxon_breadcrumbs,
          }
        elsif navigation.breadcrumbs.any?
          {
            step_by_step: false,
            breadcrumbs: navigation.breadcrumbs,
          }
        else
          {}
        end
      end
    end
  end
end
