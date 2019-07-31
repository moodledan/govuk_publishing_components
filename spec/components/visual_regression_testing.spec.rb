require 'rails_helper'
require 'percy'

describe 'screenshots', type: :feature, js: true do
  it 'screenshots' do
    visit '/component-guide'

    component_links = []

    find('#components-in-the-gem-list').all('a').each { |link|
      component_links.push link[:href]
    }

    # component_links.first(2).last(1).each{ |link|
    component_links.each { |link|
      slug = link.gsub(/http:\/\/127.0.0.1:\d{4,5}\/component-guide\//, '')

      unless slug == 'govspeak'
        visit "#{link}/preview"
        name = title.gsub(/(: Default|) preview - Component Guide/, '')
        sleep 1
        Percy.snapshot(page, name: name)
      end
    }
  end
end
