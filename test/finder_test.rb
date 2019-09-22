# frozen_string_literal: true

require 'helpers/test_helper'

class FinderTest < TestHelper
  def test_initialize_from_module
    finder = BrokenLinkFinder.new sort: :link, max_threads: 10

    assert_equal({}, finder.broken_links)
    assert_equal({}, finder.ignored_links)
    assert_equal 0, finder.total_links_crawled
    assert_equal 10, finder.max_threads
    assert_equal :link, finder.sort
    assert_equal Set, finder.instance_variable_get(:@all_broken_links).class
    assert_equal Set, finder.instance_variable_get(:@all_intact_links).class
    assert_empty finder.instance_variable_get(:@all_broken_links)
    assert_empty finder.instance_variable_get(:@all_intact_links)
    refute_nil finder.instance_variable_get(:@crawler)
  end

  def test_initialize
    finder = Finder.new

    assert_equal({}, finder.broken_links)
    assert_equal({}, finder.ignored_links)
    assert_equal 0, finder.total_links_crawled
    assert_equal 100, finder.max_threads
    assert_equal :page, finder.sort
    assert_equal Set, finder.instance_variable_get(:@all_broken_links).class
    assert_equal Set, finder.instance_variable_get(:@all_intact_links).class
    assert_empty finder.instance_variable_get(:@all_broken_links)
    assert_empty finder.instance_variable_get(:@all_intact_links)
    refute_nil finder.instance_variable_get(:@crawler)

    finder = Finder.new sort: :link, max_threads: 10
    assert_equal :link, finder.sort
    assert_equal 10, finder.max_threads
  end

  def test_clear_links
    finder = Finder.new
    finder.instance_variable_set :@broken_links, name: 'foo'
    finder.instance_variable_set :@ignored_links, name: 'bar'
    finder.clear_links

    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_equal 0, finder.total_links_crawled
    assert_empty finder.instance_variable_get(:@all_broken_links)
    assert_empty finder.instance_variable_get(:@all_intact_links)
  end

  def test_crawl_url
    finder = Finder.new
    assert finder.crawl_url 'http://mock-server.com/'

    assert_equal({
                   'http://mock-server.com/' => [
                     'https://doesnt-exist.com',
                     'not_found'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'http://mock-server.com/' => [
                     'mailto:youraddress@yourmailserver.com',
                     'tel:+13174562564'
                   ]
                 }, finder.ignored_links)
    assert_equal 8, finder.total_links_crawled
  end

  def test_crawl_url__sort_by_link
    finder = Finder.new sort: :link
    assert finder.crawl_url 'http://mock-server.com/'

    assert_equal({
                   'https://doesnt-exist.com' => [
                     'http://mock-server.com/'
                   ],
                   'not_found' => [
                     'http://mock-server.com/'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'mailto:youraddress@yourmailserver.com' => [
                     'http://mock-server.com/'
                   ],
                   'tel:+13174562564' => [
                     'http://mock-server.com/'
                   ]
                 }, finder.ignored_links)
    assert_equal 8, finder.total_links_crawled
  end

  def test_crawl_url__no_broken_links
    finder = Finder.new
    refute finder.crawl_url('http://mock-server.com/location')

    assert_equal({}, finder.broken_links)
    assert_equal({}, finder.ignored_links)
    assert_equal 2, finder.total_links_crawled
  end

  def test_crawl_url__no_broken_links__sort_by_link
    finder = Finder.new sort: :link
    refute finder.crawl_url('http://mock-server.com/location')

    assert_equal({}, finder.broken_links)
    assert_equal({}, finder.ignored_links)
    assert_equal 2, finder.total_links_crawled
  end

  def test_crawl_url__links_page
    finder = Finder.new
    assert finder.crawl_url 'https://example.co.uk/links.html'
    expected = {
      'https://example.co.uk/links.html' => [
        '/images/non-existent_logo.png',
        '/links.html#anchorthatdoesnotexist',
        '/nonexistent_page.html',
        '/nonexistent_page.html#anchorthatdoesnotexist',

        'https://example.co.uk/images/non-existing_logo.png',
        'https://example.co.uk/links.html#anchorthatdoesnotexist',
        'https://example.co.uk/nonexisting_page.html',
        'https://example.co.uk/nonexisting_page.html#anchorthatdoesnotexist',

        'https://example.com#anchorthandoesnotexist',
        'https://example.com/brokenlink',
        'https://example.com/brokenlink#anchorthandoesnotexist',
        'https://example.com/images/non-existing_logo.png',

        'https://thisdomaindoesnotexist-thouthou.com/badpage.html',
        'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist',
        'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png'
      ]
    }
    assert_equal expected, finder.broken_links
    assert_empty finder.ignored_links
    assert_equal 15, finder.total_links_crawled
  end

  def test_crawl_url__links_page__sort_by_link
    finder = Finder.new sort: :link
    assert finder.crawl_url 'https://example.co.uk/links.html'
    expected = {
      '/images/non-existent_logo.png' => ['https://example.co.uk/links.html'],
      '/nonexistent_page.html' => ['https://example.co.uk/links.html'],
      '/nonexistent_page.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html'],
      '/links.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html'],

      'https://example.com/images/non-existing_logo.png' => ['https://example.co.uk/links.html'],
      'https://example.com/brokenlink' => ['https://example.co.uk/links.html'],
      'https://example.com/brokenlink#anchorthandoesnotexist' => ['https://example.co.uk/links.html'],
      'https://example.com#anchorthandoesnotexist' => ['https://example.co.uk/links.html'],

      'https://example.co.uk/images/non-existing_logo.png' => ['https://example.co.uk/links.html'],
      'https://example.co.uk/nonexisting_page.html' => ['https://example.co.uk/links.html'],
      'https://example.co.uk/nonexisting_page.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html'],
      'https://example.co.uk/links.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html'],

      'https://thisdomaindoesnotexist-thouthou.com/badpage.html' => ['https://example.co.uk/links.html'],
      'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png' => ['https://example.co.uk/links.html'],
      'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html']
    }
    assert_equal expected, finder.broken_links
    assert_empty finder.ignored_links
    assert_equal 15, finder.total_links_crawled
  end

  def test_crawl_url__invalid
    finder = Finder.new
    finder.crawl_url 'https://server-error.com'

    flunk
  rescue RuntimeError => e
    assert_equal 'Invalid or broken URL: https://server-error.com', e.message
  end

  def test_crawl_site
    finder = Finder.new
    has_broken_links, crawled_pages = finder.crawl_site 'http://mock-server.com/'

    assert has_broken_links
    assert_equal([
                   'http://mock-server.com/',
                   'http://mock-server.com/contact',
                   'http://mock-server.com/location',
                   'http://mock-server.com/about',
                   'http://mock-server.com/not_found',
                   'http://mock-server.com/location?q=hello',
                   'http://mock-server.com/about?q=world'
                 ], crawled_pages)
    assert_equal({
                   'http://mock-server.com/' => [
                     'https://doesnt-exist.com',
                     'not_found'
                   ],
                   'http://mock-server.com/about' => [
                     'https://doesnt-exist.com'
                   ],
                   'http://mock-server.com/about?q=world' => [
                     'https://doesnt-exist.com'
                   ],
                   'http://mock-server.com/contact' => [
                     '#doesntexist',
                     'https://doesnt-exist.com',
                     'not_found'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'http://mock-server.com/' => [
                     'mailto:youraddress@yourmailserver.com',
                     'tel:+13174562564'
                   ],
                   'http://mock-server.com/contact' => [
                     'ftp://websiteaddress.com'
                   ]
                 }, finder.ignored_links)
    assert_equal 17, finder.total_links_crawled

    # Check it can be run multiple times consecutively without error.
    finder.crawl_site 'http://mock-server.com/'
  end

  def test_crawl_site__sort_by_link
    finder = Finder.new sort: :link
    has_broken_links, crawled_pages = finder.crawl_site 'http://mock-server.com/'

    assert has_broken_links
    assert_equal([
                   'http://mock-server.com/',
                   'http://mock-server.com/contact',
                   'http://mock-server.com/location',
                   'http://mock-server.com/about',
                   'http://mock-server.com/not_found',
                   'http://mock-server.com/location?q=hello',
                   'http://mock-server.com/about?q=world'
                 ], crawled_pages)
    assert_equal({
                   '#doesntexist' => [
                     'http://mock-server.com/contact'
                   ],
                   'https://doesnt-exist.com' => [
                     'http://mock-server.com/',
                     'http://mock-server.com/about',
                     'http://mock-server.com/about?q=world',
                     'http://mock-server.com/contact'
                   ],
                   'not_found' => [
                     'http://mock-server.com/',
                     'http://mock-server.com/contact'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'ftp://websiteaddress.com' => ['http://mock-server.com/contact'],
                   'mailto:youraddress@yourmailserver.com' => ['http://mock-server.com/'],
                   'tel:+13174562564' => ['http://mock-server.com/']
                 }, finder.ignored_links)
    assert_equal 17, finder.total_links_crawled

    # Check it can be run multiple times consecutively without error.
    has_broken_links, = finder.crawl_site 'http://mock-server.com/'
    assert has_broken_links
  end

  def test_crawl_site__invalid
    finder = Finder.new
    finder.crawl_site 'https://server-error.com'

    flunk
  rescue RuntimeError => e
    assert_equal 'Invalid or broken URL: https://server-error.com', e.message
  end
end
