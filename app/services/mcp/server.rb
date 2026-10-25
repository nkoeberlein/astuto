# frozen_string_literal: true

module Mcp
  # Model Context Protocol (MCP) server implementation for Astuto Evolution.
  # Implements JSON-RPC 2.0 over Streamable HTTP (/mcp) with tools for triaging
  # customer feedback, querying trends/roadmaps, and managing posts and comments.
  class Server
    SUPPORTED_PROTOCOL_VERSIONS = %w[2025-03-26 2024-11-05].freeze
    DEFAULT_PROTOCOL_VERSION = '2025-03-26'

    PARSE_ERROR      = -32_700
    INVALID_REQUEST  = -32_600
    METHOD_NOT_FOUND = -32_601
    INVALID_PARAMS   = -32_602
    INTERNAL_ERROR   = -32_603

    TOOLS = [
      {
        name: 'list_boards',
        description: 'List all feedback boards in the current tenant with their approved post counts.',
        inputSchema: {
          type: 'object',
          properties: {},
          additionalProperties: false
        },
        annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true }
      },
      {
        name: 'search_posts',
        description: 'Search feedback posts by keyword or full-text query, optionally filtered by board, status, or approval status.',
        inputSchema: {
          type: 'object',
          properties: {
            query: { type: 'string', description: 'Search query matched against post title and description.' },
            board_id: { type: 'integer', description: 'Optional board ID to filter by.' },
            post_status_id: { type: 'integer', description: 'Optional post status ID to filter by.' },
            approval_status: {
              type: 'string',
              enum: %w[approved pending rejected all],
              description: 'Approval status filter (default: approved).'
            },
            limit: { type: 'integer', description: 'Maximum number of posts to return (default: 20, max: 100).' }
          },
          additionalProperties: false
        },
        annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true }
      },
      {
        name: 'top_requests',
        description: 'List top customer feedback requests ranked by votes (most_voted) or hotness (trending).',
        inputSchema: {
          type: 'object',
          properties: {
            sort_by: {
              type: 'string',
              enum: %w[most_voted trending newest oldest],
              description: 'Ranking order (default: most_voted).'
            },
            board_id: { type: 'integer', description: 'Optional board ID to filter by.' },
            post_status_id: { type: 'integer', description: 'Optional post status ID to filter by.' },
            limit: { type: 'integer', description: 'Maximum number of posts to return (default: 20, max: 100).' }
          },
          additionalProperties: false
        },
        annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true }
      },
      {
        name: 'get_post',
        description: 'Get full details of a single feedback post (by numeric ID or slug), including votes and all comments.',
        inputSchema: {
          type: 'object',
          properties: {
            id: {
              type: %w[integer string],
              description: 'Post numeric ID or URL slug.'
            }
          },
          required: ['id'],
          additionalProperties: false
        },
        annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true }
      },
      {
        name: 'get_roadmap',
        description: 'Retrieve the public roadmap columns (statuses marked show_in_roadmap) and their assigned posts.',
        inputSchema: {
          type: 'object',
          properties: {
            limit_per_status: {
              type: 'integer',
              description: 'Maximum posts returned per roadmap status column (default: 50, max: 200).'
            }
          },
          additionalProperties: false
        },
        annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true }
      },
      {
        name: 'create_post',
        description: 'Create a new feedback post in a board on behalf of the authenticated moderator/admin.',
        inputSchema: {
          type: 'object',
          properties: {
            board_id: { type: 'integer', description: 'Target board ID.' },
            title: { type: 'string', description: 'Post title (4 to 128 characters).' },
            description: { type: 'string', description: 'Optional post description / details.' },
            post_status_id: { type: 'integer', description: 'Optional initial post status ID.' }
          },
          required: %w[board_id title],
          additionalProperties: false
        },
        annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false }
      },
      {
        name: 'update_post_status',
        description: 'Update the roadmap/workflow status (or approval status / board) of a feedback post and notify followers.',
        inputSchema: {
          type: 'object',
          properties: {
            post_id: { type: 'integer', description: 'ID of the post to update.' },
            post_status_id: {
              type: %w[integer null],
              description: 'New post status ID (or null to clear the status).'
            },
            board_id: { type: 'integer', description: 'Optional new board ID to move the post to.' },
            approval_status: {
              type: 'string',
              enum: %w[approved pending rejected],
              description: 'Optional approval status moderation change.'
            }
          },
          required: ['post_id'],
          additionalProperties: false
        },
        annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true }
      },
      {
        name: 'add_comment',
        description: 'Add a comment, reply, or official moderator status update to a feedback post.',
        inputSchema: {
          type: 'object',
          properties: {
            post_id: { type: 'integer', description: 'ID of the post to comment on.' },
            body: { type: 'string', description: 'Comment text body.' },
            parent_id: { type: 'integer', description: 'Optional parent comment ID when replying to an existing comment.' },
            is_post_update: {
              type: 'boolean',
              description: 'Whether to mark the comment as an official post update (notifies all post followers).'
            }
          },
          required: %w[post_id body],
          additionalProperties: false
        },
        annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false }
      }
    ].freeze

    def initialize(user:)
      @user = user
    end

    # Processes a parsed JSON payload (single JSON-RPC object or batch array).
    # Returns nil when the payload consists solely of notifications.
    def handle(payload)
      if payload.is_a?(Array)
        return jsonrpc_error(nil, INVALID_REQUEST, 'Invalid Request: empty batch') if payload.empty?

        responses = payload.filter_map { |item| handle_single(item) }
        responses.empty? ? nil : responses
      elsif payload.is_a?(Hash)
        handle_single(payload)
      else
        jsonrpc_error(nil, INVALID_REQUEST, 'Invalid Request')
      end
    end

    private

      def handle_single(message)
        unless message.is_a?(Hash) && message['jsonrpc'] == '2.0' && message['method'].is_a?(String)
          id = message.is_a?(Hash) ? message['id'] : nil
          return jsonrpc_error(id, INVALID_REQUEST, 'Invalid JSON-RPC 2.0 request')
        end

        id = message['id']
        method_name = message['method']
        params = message['params'] || {}

        # Notifications have no "id" member and must not produce a response object
        return nil unless message.key?('id')

        case method_name
        when 'initialize'
          requested_version = params.is_a?(Hash) ? params['protocolVersion'].to_s : ''
          version = SUPPORTED_PROTOCOL_VERSIONS.include?(requested_version) ? requested_version : DEFAULT_PROTOCOL_VERSION
          jsonrpc_result(id, {
            protocolVersion: version,
            capabilities: {
              tools: { listChanged: false }
            },
            serverInfo: {
              name: 'astuto-evolution-mcp',
              version: '2.0.0'
            },
            instructions: 'Astuto Evolution MCP server. Use these tools to search and triage customer feedback, inspect top requests and roadmaps, update post statuses, and post moderator replies.'
          })
        when 'ping'
          jsonrpc_result(id, {})
        when 'tools/list'
          jsonrpc_result(id, { tools: TOOLS })
        when 'tools/call'
          dispatch_tool_call(id, params)
        else
          jsonrpc_error(id, METHOD_NOT_FOUND, "Method not found: #{method_name}")
        end
      rescue StandardError => e
        Rails.logger.error("[MCP] Unexpected error handling #{method_name}: #{e.class}: #{e.message}")
        jsonrpc_error(id, INTERNAL_ERROR, e.message)
      end

      def dispatch_tool_call(id, params)
        unless params.is_a?(Hash) && params['name'].is_a?(String)
          return jsonrpc_error(id, INVALID_PARAMS, 'Missing tool name')
        end

        tool_name = params['name']
        args = (params['arguments'] || {}).transform_keys(&:to_s)

        unless TOOLS.any? { |t| t[:name] == tool_name }
          return jsonrpc_error(id, INVALID_PARAMS, "Unknown tool: #{tool_name}")
        end

        result = send("tool_#{tool_name}", args)
        jsonrpc_result(id, {
          content: [{ type: 'text', text: JSON.pretty_generate(result) }],
          structuredContent: result,
          isError: false
        })
      rescue ActiveRecord::RecordNotFound, ArgumentError, ActiveRecord::RecordInvalid => e
        jsonrpc_result(id, {
          content: [{ type: 'text', text: e.message }],
          isError: true
        })
      end

      def tool_list_boards(_args)
        boards = Board.order(order: :asc).map do |board|
          {
            id: board.id,
            name: board.name,
            slug: board.slug,
            description: board.description,
            order: board.order,
            approved_posts_count: board.posts.where(approval_status: 'approved').count
          }
        end
        { boards: boards }
      end

      def tool_search_posts(args)
        limit = clamp_limit(args['limit'], default: 20, max: 100)
        scope = posts_with_counts_scope
        scope = apply_approval_filter(scope, args['approval_status'])
        scope = scope.where(board_id: args['board_id'].to_i) if args['board_id'].present?
        scope = scope.where(post_status_id: args['post_status_id'].to_i) if args['post_status_id'].present?
        scope = scope.search_by_name_or_description(args['query']) if args['query'].present?
        scope = scope.order_by('most_voted').limit(limit)

        { posts: scope.map { |post| serialize_post_summary(post) } }
      end

      def tool_top_requests(args)
        limit = clamp_limit(args['limit'], default: 20, max: 100)
        sort_by = %w[most_voted trending newest oldest].include?(args['sort_by']) ? args['sort_by'] : 'most_voted'

        scope = posts_with_counts_scope.where(approval_status: 'approved')
        scope = scope.where(board_id: args['board_id'].to_i) if args['board_id'].present?
        scope = scope.where(post_status_id: args['post_status_id'].to_i) if args['post_status_id'].present?
        scope = scope.order_by(sort_by).limit(limit)

        { sort_by: sort_by, posts: scope.map { |post| serialize_post_summary(post) } }
      end

      def tool_get_post(args)
        identifier = args['id']
        raise ArgumentError, 'Parameter "id" is required' if identifier.blank?

        post = if identifier.to_s.match?(/\A\d+\z/)
                 Post.includes(:board, :post_status, :user).find_by(id: identifier.to_i) ||
                   Post.includes(:board, :post_status, :user).friendly.find(identifier.to_s)
               else
                 Post.includes(:board, :post_status, :user).friendly.find(identifier.to_s)
               end

        comments = post.comments.includes(:user).order(created_at: :asc).map do |comment|
          {
            id: comment.id,
            body: comment.body,
            parent_id: comment.parent_id,
            is_post_update: comment.is_post_update,
            author: comment.user ? { id: comment.user.id, full_name: comment.user.full_name, role: comment.user.role } : nil,
            created_at: comment.created_at.iso8601
          }
        end

        {
          post: {
            id: post.id,
            slug: post.slug,
            title: post.title,
            description: post.description,
            approval_status: post.approval_status,
            board: { id: post.board.id, name: post.board.name, slug: post.board.slug },
            post_status: post.post_status ? { id: post.post_status.id, name: post.post_status.name, color: post.post_status.color } : nil,
            author: post.user ? { id: post.user.id, full_name: post.user.full_name, role: post.user.role } : nil,
            likes_count: post.likes.count,
            comments_count: comments.size,
            created_at: post.created_at.iso8601,
            updated_at: post.updated_at.iso8601,
            comments: comments
          }
        }
      end

      def tool_get_roadmap(args)
        limit_per_status = clamp_limit(args['limit_per_status'], default: 50, max: 200)
        statuses = PostStatus.where(show_in_roadmap: true).order(order: :asc)

        columns = statuses.map do |status|
          posts = posts_with_counts_scope
            .where(approval_status: 'approved', post_status_id: status.id)
            .order_by('most_voted')
            .limit(limit_per_status)
          {
            id: status.id,
            name: status.name,
            color: status.color,
            order: status.order,
            posts: posts.map { |post| serialize_post_summary(post) }
          }
        end

        { roadmap: columns }
      end

      def tool_create_post(args)
        board = Board.find(args['board_id'])
        post_status = args['post_status_id'].present? ? PostStatus.find(args['post_status_id']) : nil

        post = Post.new(
          board: board,
          post_status: post_status,
          title: args['title'],
          description: args['description'],
          user: @user,
          approval_status: 'approved'
        )
        CreatePostWorkflow.new(post: post, follower: @user, status_actor: @user).run!

        {
          post: {
            id: post.id,
            slug: post.slug,
            title: post.title,
            description: post.description,
            board_id: post.board_id,
            post_status_id: post.post_status_id,
            approval_status: post.approval_status,
            created_at: post.created_at.iso8601
          }
        }
      end

      def tool_update_post_status(args)
        post = Post.find(args['post_id'])

        updates = {}
        if args.key?('post_status_id')
          updates[:post_status_id] = args['post_status_id'].nil? ? nil : PostStatus.find(args['post_status_id']).id
        end
        updates[:board_id] = Board.find(args['board_id']).id if args['board_id'].present?
        if args['approval_status'].present?
          unless Post.approval_statuses.key?(args['approval_status'])
            raise ArgumentError, "Invalid approval_status: #{args['approval_status']}"
          end

          updates[:approval_status] = args['approval_status']
        end

        post.assign_attributes(updates)
        status_changed = post.post_status_id_changed?
        status_change_workflow = ExecutePostStatusChangeLogicWorkflow.new(
          user_id: @user.id,
          post: post,
          post_status_id: post.post_status_id
        )

        # Post update and timeline entry together or not at all (#169); mails after commit
        ActiveRecord::Base.transaction do
          post.save!
          status_change_workflow.create_status_change! if status_changed
        end
        status_change_workflow.notify_followers if status_changed

        {
          post: {
            id: post.id,
            slug: post.slug,
            title: post.title,
            board_id: post.board_id,
            post_status_id: post.post_status_id,
            approval_status: post.approval_status,
            updated_at: post.updated_at.iso8601
          }
        }
      end

      def tool_add_comment(args)
        post = Post.find(args['post_id'])
        parent = args['parent_id'].present? ? post.comments.find(args['parent_id']) : nil
        is_post_update = ActiveModel::Type::Boolean.new.cast(args['is_post_update']) || false

        comment = Comment.create!(
          post: post,
          user: @user,
          parent: parent,
          body: args['body'],
          is_post_update: is_post_update
        )
        SendNotificationForCommentWorkflow.new(comment: comment).run

        {
          comment: {
            id: comment.id,
            post_id: comment.post_id,
            parent_id: comment.parent_id,
            body: comment.body,
            is_post_update: comment.is_post_update,
            created_at: comment.created_at.iso8601
          }
        }
      end

      def posts_with_counts_scope
        Post
          .select(
            'posts.id',
            'posts.title',
            'posts.slug',
            'posts.description',
            'posts.board_id',
            'posts.post_status_id',
            'posts.approval_status',
            'posts.created_at',
            'posts.updated_at',
            'COUNT(DISTINCT likes.id) AS likes_count',
            'COUNT(DISTINCT comments.id) AS comments_count',
            '((LOG(COUNT(DISTINCT likes.id) + 1) + LOG(COUNT(DISTINCT comments.id) + 1)) + (EXTRACT(EPOCH FROM posts.created_at) / 45000)) AS hotness'
          )
          .left_outer_joins(:likes, :comments)
          .group('posts.id')
      end

      def apply_approval_filter(scope, approval_status)
        case approval_status
        when 'pending', 'rejected'
          scope.where(approval_status: approval_status)
        when 'all'
          scope
        else
          scope.where(approval_status: 'approved')
        end
      end

      def serialize_post_summary(post)
        {
          id: post.id,
          slug: post.slug,
          title: post.title,
          description: post.description,
          board_id: post.board_id,
          post_status_id: post.post_status_id,
          approval_status: post.approval_status,
          likes_count: post.likes_count.to_i,
          comments_count: post.comments_count.to_i,
          created_at: post.created_at.iso8601
        }
      end

      def clamp_limit(value, default:, max:)
        num = value.to_i
        return default if num <= 0

        [num, max].min
      end

      def jsonrpc_result(id, result)
        { jsonrpc: '2.0', id: id, result: result }
      end

      def jsonrpc_error(id, code, message)
        { jsonrpc: '2.0', id: id, error: { code: code, message: message } }
      end
  end
end
