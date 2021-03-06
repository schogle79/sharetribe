class LandingPageController < ActionController::Metal

  class Denormalizer

    def initialize(root: "composition", link_resolvers: {})
      @root = root
      @link_resolvers = link_resolvers
    end

    def to_tree(normalized_data)
      root = normalized_data[@root]

      deep_map(root) { |k, v|
        case v
        when Hash
          type, id = v.values_at("type", "id")

          new_v =
            if type.nil?
              # Not a link
              v
            elsif id.nil?
              # Looks like link, but no ID. That's an error.
              raise ArgumentError.new("Invalid link: #{v.inspect} has a 'type' key but no 'id'")
            else
              # Is a link
              resolve_link(type, id, normalized_data)
            end

          [k, new_v]
        else
          [k, v]
        end
      }
    end

    # Recursively walks through nested hash and performs `map` operation.
    #
    # The tree is traversed in pre-order manner.
    #
    # In each node, calls the block with two arguments: key and value.
    # The block needs to return a tuple of [key, value].
    #
    # Example (double all values):
    #
    # deep_map(a: { b: { c: 1}, d: [{ e: 1, f: 2 }]}) { |k, v|
    #   [k, v * 2]
    # }
    #
    #
    # Example (stringify keys):
    #
    # deep_map(a: 1, b: 2) { |k, v|
    #   [k.to_s, v]
    # }
    #
    # Unlike Ruby's Hash#map, this method returns a Hash, not an Array.
    #
    def deep_map(obj, &block)
      case obj
      when Hash
        obj.map { |k, v|
          deep_map(block.call(k, v), &block)
        }.to_h
      when Array
        obj.map { |x| deep_map(x, &block) }
      else
        obj
      end
    end

    private

    def resolve_link(type, id, normalized_data)
      if @link_resolvers[type].respond_to? :call
        @link_resolvers[type].call(type, id, normalized_data)
      else
        normalized_data[type][id]
      end
    end
  end

  # Needed for rendering
  #
  # See Rendering Helpers: http://api.rubyonrails.org/classes/ActionController/Metal.html
  #
  include AbstractController::Rendering
  include ActionView::Layouts
  append_view_path "#{Rails.root}/app/views"

  def index
    landing_page
  end

  private

  def landing_page
    denormalizer = Denormalizer.new(
      link_resolvers: {
        "assets" => ->(type, id, normalized_data) {
          append_asset_dir(normalized_data[type][id])
        }
      })

    render :landing_page, locals: { sections: denormalizer.to_tree(data) }
  end

  def append_asset_dir(file)
    ["landing_page", file].join("/")
  end

  def data
    {
      "settings" => {
        "marketplace_id" => 9999,
        "locale" => "en",
        "sitename" => "turbobikes"
      },

      "sections" => {
        "myhero1" => {
          "kind" => "hero",
          "title" => "Sell your turbobike",
          "subtitle" => "The best place to rent your turbojopo",
          "background_image" => {"type" => "assets", "id" => "myheroimage"},
          "search_placeholder" => "What kind of turbojopo are you looking for?",
          "search_button" => "Search",
        },
        "thecategories" => {"type" => "categories", "slogan" => "blaablaa", "category_ids" => [123, 432, 131]},
      },

      "composition" => [
        { "section" => {"type" => "sections", "id" => "myhero1"},
          "disabled" => false},
        { "section" => {"type" => "sections", "id" => "myhero1"},
          "disabled" => false},
        { "section" => {"type" => "sections", "id" => "myhero1"},
          "disabled" => true},
      ],

      "assets" => {
        "myheroimage" => "hero.png",
      }
    }
  end
end
