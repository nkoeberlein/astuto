require 'swagger_helper'

RSpec.describe 'api/app/v1 tags', type: :request, openapi_spec: 'app/v1/openapi.yaml' do
  let(:admin) { FactoryBot.create(:admin).tap(&:confirm) }
  let!(:mobile) { Tag.create!(name: 'Mobile', color: '#0ea5e9') }
  let!(:billing) { Tag.create!(name: 'Billing') }

  path '/api/app/v1/tags' do
    get('Tags in their order') do
      tags 'Tags'
      produces 'application/json'

      response(200, 'tags') do
        schema type: :array, items: { '$ref' => '#/components/schemas/Tag' }

        run_test! { |response| expect(JSON.parse(response.body).map { |t| t['name'] }).to eq(%w[Mobile Billing]) }
      end
    end

    post('Create a tag (admins)') do
      tags 'Tags'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :tag, in: :body, schema: { '$ref' => '#/components/schemas/TagInput' }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/Tag'
        let(:tag) { { name: '  Integrations ', color: '#22c55e' } }
        before { sign_in admin }

        run_test! do |response|
          expect(JSON.parse(response.body)).to include('name' => 'Integrations', 'order' => 2)
          expect(AuditEvent.last.action).to eq('tag.create')
        end
      end

      response(422, 'duplicate name') do
        schema '$ref' => '#/components/schemas/Error'
        let(:tag) { { name: 'mobile' } }
        before { sign_in admin }

        run_test!
      end
    end
  end

  path '/api/app/v1/tags/{id}' do
    parameter name: :id, in: :path, type: :integer

    patch('Rename or recolor a tag (admins)') do
      tags 'Tags'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :tag, in: :body, schema: { '$ref' => '#/components/schemas/TagInput' }

      response(200, 'saved') do
        schema '$ref' => '#/components/schemas/Tag'
        let(:id) { mobile.id }
        let(:tag) { { name: 'Mobile apps' } }
        before { sign_in admin }

        run_test! { |response| expect(JSON.parse(response.body)['name']).to eq('Mobile apps') }
      end
    end

    delete('Delete a tag; it goes away from all posts (admins)') do
      tags 'Tags'

      response(204, 'deleted') do
        let(:id) { billing.id }
        before do
          FactoryBot.create(:post).tags << billing
          sign_in admin
        end

        run_test! { expect(PostTag.count).to eq(0) }
      end
    end
  end

  path '/api/app/v1/tags/reorder' do
    put('Order of the tags (admins)') do
      tags 'Tags'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :order, in: :body, schema: { type: :object, properties: { ids: { type: :array, items: { type: :integer } } }, required: ['ids'] }

      response(200, 'new order') do
        schema type: :array, items: { '$ref' => '#/components/schemas/Tag' }
        let(:order) { { ids: [billing.id, mobile.id] } }
        before { sign_in admin }

        run_test! { |response| expect(JSON.parse(response.body).map { |t| t['name'] }).to eq(%w[Billing Mobile]) }
      end
    end
  end
end
