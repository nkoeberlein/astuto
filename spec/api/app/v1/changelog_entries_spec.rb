require 'swagger_helper'

RSpec.describe 'api/app/v1 changelog', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:moderator) { FactoryBot.create(:moderator).tap(&:confirm) }
  let(:user) { FactoryBot.create(:user).tap(&:confirm) }
  let!(:done_post) { FactoryBot.create(:post, title: 'Dark mode', post_status: FactoryBot.create(:post_status, name: 'Done')) }
  let!(:published) do
    ChangelogEntry.create!(title: 'October release', body: '- Dark mode', published_at: 1.day.ago).tap do |entry|
      entry.changelog_entry_posts.create!(post: done_post)
    end
  end
  let!(:draft) { ChangelogEntry.create!(title: 'Next release', body: 'Soon') }

  path '/api/app/v1/changelog_entries' do
    get('Changelog entries, newest first (moderators also see drafts, which come first)') do
      tags 'Changelog'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false

      response(200, 'published entries') do
        schema '$ref' => '#/components/schemas/ChangelogEntryPage'

        run_test! do |response|
          entries = JSON.parse(response.body)['entries']
          expect(entries.map { |e| e['title'] }).to eq(['October release'])
          expect(entries.first['posts']).to eq([{ 'id' => done_post.id, 'title' => 'Dark mode', 'slug' => done_post.slug }])
        end
      end
    end

    post('Write a changelog entry (moderators)') do
      tags 'Changelog'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :entry, in: :body, schema: { '$ref' => '#/components/schemas/ChangelogEntryInput' }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/ChangelogEntry'
        let(:entry) { { title: 'November release', body: 'Faster search', postIds: [done_post.id], published: false } }
        before { sign_in moderator }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body).to include('title' => 'November release', 'publishedAt' => nil)
          expect(body['posts'].map { |p| p['id'] }).to eq([done_post.id])
          expect(AuditEvent.last.action).to eq('changelog.create')
        end
      end

      response(403, 'not a moderator') do
        schema '$ref' => '#/components/schemas/Error'
        let(:entry) { { title: 'Nope' } }
        before { sign_in user }

        run_test!
      end

      response(422, 'invalid') do
        schema '$ref' => '#/components/schemas/Error'
        let(:entry) { { title: '' } }
        before { sign_in moderator }

        run_test!
      end
    end
  end

  path '/api/app/v1/changelog_entries/{id}' do
    parameter name: :id, in: :path, type: :integer

    patch('Change, publish or unpublish a changelog entry (moderators)') do
      tags 'Changelog'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :entry, in: :body, schema: { '$ref' => '#/components/schemas/ChangelogEntryInput' }

      response(200, 'saved') do
        schema '$ref' => '#/components/schemas/ChangelogEntry'
        let(:id) { draft.id }
        let(:entry) { { published: true } }
        before { sign_in moderator }

        run_test! do |response|
          expect(JSON.parse(response.body)['publishedAt']).to be_present
          expect(AuditEvent.pluck(:action)).to include('changelog.update', 'changelog.publish')
        end
      end
    end

    delete('Delete a changelog entry (moderators)') do
      tags 'Changelog'

      response(204, 'deleted') do
        let(:id) { published.id }
        before { sign_in moderator }

        run_test! { expect(ChangelogEntry.exists?(published.id)).to be(false) }
      end
    end
  end

  path '/api/app/v1/changelog_entries/linkable_posts' do
    get('Approved posts to link to an entry, posts with a status first (moderators)') do
      tags 'Changelog'
      produces 'application/json'
      parameter name: :search, in: :query, type: :string, required: false

      response(200, 'posts') do
        schema type: :array, items: { '$ref' => '#/components/schemas/LinkablePost' }
        let(:search) { 'dark' }
        before do
          FactoryBot.create(:post, title: 'Something else')
          sign_in moderator
        end

        run_test! { |response| expect(JSON.parse(response.body).map { |p| p['title'] }).to eq(['Dark mode']) }
      end
    end
  end

  path '/api/app/v1/changelog_entries/draft' do
    post('AI draft of the text from the linked posts (moderators, needs AI_PROVIDER and AI_MODEL)') do
      tags 'Changelog'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :input, in: :body, schema: { '$ref' => '#/components/schemas/ChangelogDraftInput' }

      let(:ai_client) { instance_double(Ai::Client, enabled?: true) }
      before do
        allow(Ai::Client).to receive(:from_env).and_return(ai_client)
        allow(ai_client).to receive(:draft_changelog).and_return('- Dark mode is here')
        sign_in moderator
      end

      response(200, 'draft') do
        schema '$ref' => '#/components/schemas/ChangelogDraft'
        let(:input) { { postIds: [done_post.id] } }

        run_test! do |response|
          expect(JSON.parse(response.body)).to eq('body' => '- Dark mode is here')
          expect(ai_client).to have_received(:draft_changelog).with(posts: [done_post], locale: I18n.locale)
        end
      end

      response(404, 'AI is not configured') do
        schema '$ref' => '#/components/schemas/Error'
        let(:input) { { postIds: [done_post.id] } }
        before { allow(ai_client).to receive(:enabled?).and_return(false) }

        run_test!
      end
    end
  end
end
