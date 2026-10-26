require 'rails_helper'

# Loads the main pages in Chrome and fails on any Content Security Policy
# violation in the browser console, for the legacy UI and the v2 frontend.
feature 'Content Security Policy in the browser', type: :system, js: true do
  let(:board) { FactoryBot.create(:board) }
  let(:post_record) { FactoryBot.create(:post, board: board) }
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }

  def csp_violations
    page.driver.browser.logs.get(:browser)
      .map(&:message)
      .select { |message| message.match?(/Content Security Policy|Refused to (execute|load|apply)/i) }
  end

  def expect_no_csp_violations_on(path)
    visit path
    # Wait for the React components to mount
    expect(page).to have_css('body')
    sleep 0.5
    # Reading the log empties it, so read it once
    violations = csp_violations
    expect(violations).to be_empty, "CSP violations on #{path}:\n#{violations.join("\n")}"
  end

  it 'loads the legacy pages without violations' do
    FactoryBot.create(:comment, post: post_record)

    expect_no_csp_violations_on(board_path(board))
    expect_no_csp_violations_on(post_path(post_record))
    expect_no_csp_violations_on(roadmap_path)
    expect_no_csp_violations_on(new_user_session_path)
  end

  it 'keeps the legacy UI working for a signed-in user' do
    sign_in user

    expect_no_csp_violations_on(post_path(post_record))
    expect(page).to have_css('.postAndCommentsContainer, .postTitle', wait: 15)
  end

  it 'loads the v2 frontend without violations' do
    skip 'v2 frontend not built' unless SpaController::INDEX.exist?

    expect_no_csp_violations_on("/next/boards/#{board.slug}")
    expect_no_csp_violations_on("/next/posts/#{post_record.slug}")
  end
end
