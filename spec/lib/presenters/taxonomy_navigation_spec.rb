require 'spec_helper'
require 'webmock/rspec'
require 'gds_api/test_helpers/rummager'

RSpec.describe GovukPublishingComponents::Presenters::TaxonomyNavigation do
  include GdsApi::TestHelpers::Rummager

  describe '#sidebar' do
    it 'can handle any valid content item' do
      stub_any_rummager_search_to_return_no_results

      payload = GovukSchemas::RandomExample.for_schema(
        frontend_schema: 'placeholder',
      )

      expect { sidebar_for(payload) }.to_not raise_error
    end

    context 'given a content item not tagged to any taxon with no document collections' do
      it 'returns an empty sidebar hash' do
        content_item = { "links" => {} }

        expect(sidebar_for(content_item)).to eq(
          items: [],
          collections: [],
          statistical_data_sets: [],
          topical_events: [],
          world_locations: [],
        )
      end
    end

    context 'given a content item tagged to taxons with no related content' do
      it 'returns a sidebar hash containing a sorted list of parent taxons' do
        content_item = content_item_tagged_to_taxon

        expect(sidebar_for(content_item)).to eq(
          items: [
            {
              title: "Taxon A",
              url: "/taxon-a",
              description: "The A taxon.",
              related_content: [],
            },
            {
              title: "Taxon B",
              url: "/taxon-b",
              description: "The B taxon.",
              related_content: [],
            },
          ],
          collections: [],
          statistical_data_sets: [],
          topical_events: [],
          world_locations: [],
        )
      end
    end

    context 'when there are related link overrides' do
      context 'belonging to the same taxon' do
        it 'displays the related link overrides under a single taxon' do
          content_item = content_item_tagged_to_taxon

          content_item['links']['ordered_related_items_overrides'] = [
            {
              'title' => 'Related link override B',
              'base_path' => '/override-b',
              'content_id' => 'override-b',
              'links' => {
                'taxons' => [
                  content_item['links']['taxons'][0],
                ],
              },
            },
          ]

          expect(sidebar_for(content_item)).to eq(
            items: [
              {
                title: "Taxon A",
                url: "/taxon-a",
                description: "The A taxon.",
                related_content: [],
              },
              {
                title: "Taxon B",
                url: "/taxon-b",
                description: "The B taxon.",
                related_content: [
                  { title: 'Related link override B', link: '/override-b' },
                ],
              }
            ],
            collections: [],
            statistical_data_sets: [],
            topical_events: [],
            world_locations: [],
          )
        end

        it 'displays the related link overrides under a multiple taxons' do
          content_item = content_item_tagged_to_taxon

          content_item['links']['ordered_related_items_overrides'] = [
            {
              'title' => 'Related link override B',
              'base_path' => '/override-b',
              'content_id' => 'override-b',
              'links' => {
                'taxons' => [
                  content_item['links']['taxons'][0],
                ],
              },
            },
            {
              'title' => 'Related link override A-2',
              'base_path' => '/override-a-2',
              'content_id' => 'override-a-2',
              'links' => {
                'taxons' => [
                  content_item['links']['taxons'][1],
                ],
              },
            },
            {
              'title' => 'Related link override A-1',
              'base_path' => '/override-a-1',
              'content_id' => 'override-a-1',
              'links' => {
                'taxons' => [
                  content_item['links']['taxons'][1],
                ],
              },
            },
          ]

          expect(sidebar_for(content_item)).to eq(
            items: [
              {
                title: "Taxon A",
                url: "/taxon-a",
                description: "The A taxon.",
                related_content: [
                  { 'title': 'Related link override A-1', 'link': '/override-a-1' },
                  { 'title': 'Related link override A-2', 'link': '/override-a-2' },
                ],
              },
              {
                title: "Taxon B",
                url: "/taxon-b",
                description: "The B taxon.",
                related_content: [
                  { 'title': 'Related link override B', 'link': '/override-b' },
                ],
              }
            ],
            collections: [],
            statistical_data_sets: [],
            topical_events: [],
            world_locations: [],
          )
        end

        it 'displays a related link tagged to multiple taxons under a single taxon' do
          content_item = content_item_tagged_to_taxon

          content_item['links']['ordered_related_items_overrides'] = [
            {
              'title' => 'Related link override',
              'base_path' => '/override',
              'content_id' => 'override',
              'links' => {
                'taxons' => [
                  content_item['links']['taxons'][0],
                  content_item['links']['taxons'][1],
                ],
              },
            },
          ]

          expect(sidebar_for(content_item)).to eq(
            items: [
              {
                title: "Taxon A",
                url: "/taxon-a",
                description: "The A taxon.",
                related_content: [
                  { 'title': 'Related link override', 'link': '/override' },
                ],
              },
              {
                title: "Taxon B",
                url: "/taxon-b",
                description: "The B taxon.",
                related_content: [],
              }
            ],
            collections: [],
            statistical_data_sets: [],
            topical_events: [],
            world_locations: [],
          )
        end

        it 'displays a related link tagged to another taxon under "Elsewhere"' do
          content_item = content_item_tagged_to_taxon

          content_item['links']['ordered_related_items_overrides'] = [
            {
              'title' => 'Related link override',
              'base_path' => '/override',
              'content_id' => 'override',
              'links' => {
                'taxons' => [
                  {
                    'title' => 'Some other taxon',
                    'content_id' => 'some-other-taxon',
                    'base_path' => '/some-other-taxon',
                  }
                ],
              },
            },
          ]

          expect(sidebar_for(content_item)).to eq(
            items: [
              {
                title: "Taxon A",
                url: "/taxon-a",
                description: "The A taxon.",
                related_content: [],
              },
              {
                title: "Taxon B",
                url: "/taxon-b",
                description: "The B taxon.",
                related_content: [],
              },
              {
                title: "Elsewhere on GOV.UK",
                related_content: [
                  { title: 'Related link override', link: '/override' }
                ],
              },
            ],
            collections: [],
            statistical_data_sets: [],
            topical_events: [],
            world_locations: [],
          )
        end

        it 'displays a related link not tagged to any taxons under "Elsewhere"' do
          content_item = content_item_tagged_to_taxon

          content_item['links']['ordered_related_items_overrides'] = [
            {
              'title' => 'Related link override',
              'base_path' => '/override',
              'content_id' => 'override',
              'links' => {},
            },
          ]

          expect(sidebar_for(content_item)).to eq(
            items: [
              {
                title: "Taxon A",
                url: "/taxon-a",
                description: "The A taxon.",
                related_content: [],
              },
              {
                title: "Taxon B",
                url: "/taxon-b",
                description: "The B taxon.",
                related_content: [],
              },
              {
                title: "Elsewhere on GOV.UK",
                related_content: [
                  { title: 'Related link override', link: '/override' }
                ],
              },
            ],
            collections: [],
            statistical_data_sets: [],
            topical_events: [],
            world_locations: [],
          )
        end

        it 'displays an external related link under "Elsewhere"' do
          content_item = content_item_tagged_to_taxon

          content_item['links']['ordered_related_items_overrides'] = [
            {
              'title' => 'Related link override',
              'base_path' => '/override',
              'content_id' => 'override',
              'links' => {},
            },
          ]

          content_item['details'] = {
            'external_related_links' => [
              {
                'title' => 'External related link',
                'url' => 'http://example.com',
              },
            ]
          }

          expect(sidebar_for(content_item)).to eq(
            items: [
              {
                title: "Taxon A",
                url: "/taxon-a",
                description: "The A taxon.",
                related_content: [],
              },
              {
                title: "Taxon B",
                url: "/taxon-b",
                description: "The B taxon.",
                related_content: [],
              },
              {
                title: "Elsewhere on GOV.UK",
                related_content: [
                  { title: 'Related link override', link: '/override' }
                ],
              },
              {
                title: "Elsewhere on the web",
                related_content: [
                  { title: 'External related link', link: 'http://example.com' }
                ],
              },
            ],
            collections: [],
            statistical_data_sets: [],
            topical_events: [],
            world_locations: [],
          )
        end
      end
    end

    context 'given a content item with document collections' do
      it 'returns a sidebar hash containing document collections' do
        expect(sidebar_for(content_item_with_document_collections)).to eq(
          items: [],
          collections: [
            {
              path: "/collection-b",
              text: "Collection B",
            },
            {
              path: "/collection-a",
              text: "Collection A",
            },
          ],
          statistical_data_sets: [],
          topical_events: [],
          world_locations: [],
        )
      end
    end

    context 'given a content item with statistical data sets' do
      it 'returns a sidebar hash containing statistical data sets' do
        expect(sidebar_for(content_item_with_statistical_data_sets)).to eq(
          items: [],
          collections: [],
          statistical_data_sets: [
            { path: "/statistical-data-set-b", text: "Statistical data set B" },
            { path: "/statistical-data-set-a", text: "Statistical data set A" },
          ],
          topical_events: [],
          world_locations: [],
        )
      end
    end

    context 'given a content item with topical events' do
      it 'returns a sidebar hash containing topical events' do
        expect(sidebar_for(content_item_with_topical_events)).to eq(
          items: [],
          collections: [],
          statistical_data_sets: [],
          topical_events: [{ path: "/topical-event-b", text: "Topical event B" }],
          world_locations: [],
        )
      end
    end

    context 'given a content item with world locations' do
      it 'returns a sidebar hash containing world locations' do
        expect(sidebar_for(content_item_with_world_locations)).to eq(
          items: [],
          collections: [],
          statistical_data_sets: [],
          topical_events: [],
          world_locations: [{ path: "/world/world-location-b/news", text: "World location B" }],
        )
      end
    end
  end

  def sidebar_for(content_item)
    described_class.new(content_item).sidebar
  end

  def content_item_tagged_to_taxon
    {
      "title" => "A piece of content",
      "base_path" => "/a-piece-of-content",
      "links" => {
        "taxons" => [
          {
            "title" => "Taxon B",
            "base_path" => "/taxon-b",
            "content_id" => "taxon-b",
            "description" => "The B taxon.",
            "phase" => "live",
          },
          {
            "title" => "Taxon A",
            "base_path" => "/taxon-a",
            "content_id" => "taxon-a",
            "description" => "The A taxon.",
            "phase" => "live",
          },
        ],
      },
    }
  end

  def content_item_with_document_collections
    content_item_with(
      "document_collections" => [
        {
          "title" => "Collection B",
          "base_path" => "/collection-b",
          "content_id" => "collection-b",
          "document_type" => "document_collection",
        },
        {
          "title" => "Collection A",
          "base_path" => "/collection-a",
          "content_id" => "collection-a",
          "document_type" => "document_collection",
        },
      ]
    )
  end

  def content_item_with_statistical_data_sets
    content_item_with(
      "related_statistical_data_sets" => [
        {
          "title" => "Statistical data set B",
          "base_path" => "/statistical-data-set-b",
          "content_id" => "statistical-data-set-b",
          "document_type" => "statistical_data_set",
        },
        {
          "title" => "Statistical data set A",
          "base_path" => "/statistical-data-set-a",
          "content_id" => "statistical-data-set-a",
          "document_type" => "statistical_data_set",
        },
      ]
    )
  end

  def content_item_with_topical_events
    content_item_with(
      "topical_events" => [
        {
          "title" => "Topical event B",
          "base_path" => "/topical-event-b",
          "content_id" => "topical-event-b",
          "document_type" => "topical_event",
        },
      ]
    )
  end

  def content_item_with_world_locations
    content_item_with(
      "world_locations" => [
        {
          "title" => "World location B",
          "base_path" => "/world-location-b",
          "content_id" => "world-location-b",
          "document_type" => "world_location",
        },
      ]
    )
  end

  def content_item_with(links)
    {
      "title" => "A piece of content",
      "base_path" => "/a-piece-of-content",
      "links" => links
    }
  end
end
