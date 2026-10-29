class CreateLiquidTemplateContextWorkflow
  TENANT_ATTRIBUTES = [:site_name, :subdomain, :custom_domain].freeze
  BOARD_ATTRIBUTES = [:id, :name, :description, :slug, :created_at, :updated_at].freeze
  POST_STATUS_ATTRIBUTES = [:id, :name, :color, :show_in_roadmap, :created_at, :updated_at].freeze
  USER_ATTRIBUTES = [:id, :email, :full_name, :role, :status, :created_at, :updated_at].freeze
  POST_ATTRIBUTES = [:id, :title, :description, :slug, :board_id, :user_id, :created_at, :updated_at].freeze
  POST_VIRTUAL_ATTRIBUTES = [:url].freeze
  COMMENT_ATTRIBUTES = [:id, :body, :user_id, :post_id, :created_at, :updated_at].freeze

  # Variables each trigger offers in templates: context key => attributes
  # (the frontend reads them from /api/app/v1/site_settings/webhooks/variables)
  POST_VARIABLES = POST_ATTRIBUTES + POST_VIRTUAL_ATTRIBUTES
  TEMPLATE_VARIABLES = {
    'new_post' => { post: POST_VARIABLES, post_author: USER_ATTRIBUTES, board: BOARD_ATTRIBUTES },
    'new_post_pending_approval' => { post: POST_VARIABLES, post_author: USER_ATTRIBUTES, board: BOARD_ATTRIBUTES },
    'delete_post' => { post: [:id] },
    'post_status_change' => { post: POST_VARIABLES, post_author: USER_ATTRIBUTES, board: BOARD_ATTRIBUTES, post_status: POST_STATUS_ATTRIBUTES },
    'new_comment' => { comment: COMMENT_ATTRIBUTES, comment_author: USER_ATTRIBUTES, post: POST_VARIABLES, post_author: USER_ATTRIBUTES, board: BOARD_ATTRIBUTES },
    'new_vote' => { vote_author: USER_ATTRIBUTES, post: POST_VARIABLES, post_author: USER_ATTRIBUTES, board: BOARD_ATTRIBUTES },
    'new_user' => { user: USER_ATTRIBUTES }
  }.freeze

  # ["post.id", "post.title", ..., "tenant.site_name"] for a trigger
  def self.variables_for(trigger)
    groups = TEMPLATE_VARIABLES.fetch(trigger.to_s, {}).merge(tenant: TENANT_ATTRIBUTES)
    groups.flat_map { |name, attributes| attributes.map { |attribute| "#{name}.#{attribute}" } }
  end

  attr_accessor :webhook_trigger, :is_test, :entities

  def initialize(webhook_trigger: "new_post", is_test: false, entities: {})
    @webhook_trigger = webhook_trigger
    @entities = entities

    if is_test
      board_test_entity = Board.new(
        id: 0,
        name: 'Example board for webhook testing',
        description: 'This is just an example board for testing webhooks out! Do not worry: this board is not saved anywhere in your feedback space ;)',
        slug: 'example-board',
        created_at: Time.now,
        updated_at: Time.now,
      )

      post_status_test_entity = PostStatus.new(
        id: 0,
        name: 'Example post status',
        color: '#000000',
        show_in_roadmap: true,
        created_at: Time.now,
        updated_at: Time.now,
      )

      user_test_entity = User.new(
        id: 0,
        email: 'user@example.com',
        full_name: 'Test User',
        role: 'user',
        status: 'active',
        created_at: Time.now,
        updated_at: Time.now,
      )

      post_author_test_entity = User.new(
        id: 0,
        email: 'user1@example.com',
        full_name: 'Test User Post Author',
        role: 'user',
        status: 'active',
        created_at: Time.now,
        updated_at: Time.now,
      )

      comment_author_test_entity = User.new(
        id: 0,
        email: 'user2@example.com',
        full_name: 'Test User Comment Author',
        role: 'user',
        status: 'active',
        created_at: Time.now,
        updated_at: Time.now,
      )

      vote_author_test_entity = User.new(
        id: 0,
        email: 'user3@example.com',
        full_name: 'Test User Vote Author',
        role: 'user',
        status: 'active',
        created_at: Time.now,
        updated_at: Time.now,
      )

      post_test_entity = Post.new(
        id: 0,
        title: 'Example post for webhook testing',
        description: 'This is just an example post for testing webhooks out! Do not worry: this post is not saved anywhere in your feedback space ;)',
        slug: 'example-post',
        board_id: 0,
        user_id: 0,
        created_at: Time.now,
        updated_at: Time.now,
      )

      comment_test_entity = Comment.new(
        id: 0,
        body: 'This is just an example comment for testing webhooks out!',
        user_id: 0,
        post_id: 0,
        created_at: Time.now,
        updated_at: Time.now,
      )
      
      @entities = {
        board: board_test_entity,
        post_status: post_status_test_entity,
        user: user_test_entity,
        post_author: post_author_test_entity,
        comment_author: comment_author_test_entity,
        vote_author: vote_author_test_entity,
        post: post_test_entity,
        comment: comment_test_entity,

        # for delete_post trigger
        post_id: 0,
      }
    end
  end

  def run
    tenant = Current.tenant_or_raise!
    context = {}

    # Add general context variables
    context['tenant'] = tenant.as_json(only: TENANT_ATTRIBUTES)

    # Add context variables specific to the webhook trigger
    # Must match TEMPLATE_VARIABLES above
    case webhook_trigger
    when 'new_post'
      context['post'] = @entities[:post].as_json(only: POST_ATTRIBUTES, methods: POST_VIRTUAL_ATTRIBUTES)
      context['post_author'] = @entities.key?(:post_author) ? @entities[:post_author].as_json(only: USER_ATTRIBUTES) : nil
      context['board'] = @entities[:board].as_json(only: BOARD_ATTRIBUTES)

    when 'new_post_pending_approval'
      context['post'] = @entities[:post].as_json(only: POST_ATTRIBUTES, methods: POST_VIRTUAL_ATTRIBUTES)
      context['post_author'] = @entities.key?(:post_author) ? @entities[:post_author].as_json(only: USER_ATTRIBUTES) : nil
      context['board'] = @entities[:board].as_json(only: BOARD_ATTRIBUTES)

    when 'delete_post'
      context['post'] = { id: @entities[:post_id] }.as_json

    when 'post_status_change'
      context['post'] = @entities[:post].as_json(only: POST_ATTRIBUTES, methods: POST_VIRTUAL_ATTRIBUTES)
      context['post_author'] = @entities.key?(:post_author) ? @entities[:post_author].as_json(only: USER_ATTRIBUTES) : nil
      context['board'] = @entities[:board].as_json(only: BOARD_ATTRIBUTES)
      context['post_status'] = @entities.key?(:post_status) ? @entities[:post_status].as_json(only: POST_STATUS_ATTRIBUTES) : { name: I18n.t('post.post_status_select.no_post_status'), color: '#000000' }.as_json

    when 'new_comment'
      context['comment'] = @entities[:comment].as_json(only: COMMENT_ATTRIBUTES)
      context['comment_author'] = @entities[:comment_author].as_json(only: USER_ATTRIBUTES)
      context['post'] = @entities[:post].as_json(only: POST_ATTRIBUTES, methods: POST_VIRTUAL_ATTRIBUTES)
      context['post_author'] = @entities.key?(:post_author) ? @entities[:post_author].as_json(only: USER_ATTRIBUTES) : nil
      context['board'] = @entities[:board].as_json(only: BOARD_ATTRIBUTES)

    when 'new_vote'
      context['vote_author'] = @entities[:vote_author].as_json(only: USER_ATTRIBUTES)
      context['post'] = @entities[:post].as_json(only: POST_ATTRIBUTES, methods: POST_VIRTUAL_ATTRIBUTES)
      context['post_author'] = @entities.key?(:post_author) ? @entities[:post_author].as_json(only: USER_ATTRIBUTES) : nil
      context['board'] = @entities[:board].as_json(only: BOARD_ATTRIBUTES)

    when 'new_user'
      context['user'] = @entities[:user].as_json(only: USER_ATTRIBUTES)
    end

    context
  end
end