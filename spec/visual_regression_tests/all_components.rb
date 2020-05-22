require "rails_helper"
require "percy"

describe "visual regression test runner Percy", type: :feature, js: true do
  it "takes a screenshot of each component" do
    visit "/component-guide"

    component_links = []

    find("#components-in-the-gem-list").all("a").each do |link|
      component_links.push link[:href]
    end

    # component_links.first(2).last(1).each{ |link|
    component_links.each do |link|
      slug = link.gsub(/http:\/\/127.0.0.1:\d{4,5}\/component-guide\//, "")

      next if slug == "govspeak" # skip Govspeak because it's just too long

      visit "#{link}/preview"
      name = title.gsub(/(: Default|) preview - Component Guide/, "")
      page.find(:css, "#wrapper", wait: 10)
      Percy.snapshot(page, name: name)
    end
  end
end
