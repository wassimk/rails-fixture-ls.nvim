# frozen_string_literal: true

require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test 'published posts are visible' do
    post = posts(:welcome)

    assert_predicate post, :published?
  end

  test 'draft posts belong to a user' do
    post = posts(:draft)
    user = users(:bob)

    assert_equal user, post.user
  end

  test 'posts can have comments' do
    post = posts(:welcome)
    comment = comments(:positive)

    assert_includes post.comments, comment
  end
end
