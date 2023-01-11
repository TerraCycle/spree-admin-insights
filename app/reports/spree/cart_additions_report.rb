# frozen_string_literal: true

module Spree
  # Cart Additions Report
  class CartAdditionsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { sku: :string, product_name: :string, additions: :integer,
                                   quantity_change: :integer }.freeze
    SEARCH_ATTRIBUTES          = { start_date: :product_added_from,
                                   end_date: :product_added_to }.freeze
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :additions, :quantity_change].freeze

    deeplink product_name: {
      template: %(
        <a href="/#{I18n.locale}/admin/products/{%# o.product_slug %}" target="_blank">
        {%# o.product_name %}</a>
      )
    }

    class Result < Spree::Report::Result
      # Observation class
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :additions, :quantity_change, :sku]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      Spree::CartEvent
        .added
        .joins(variant: { product: :translations })
        .joins(variant: { product: :stores })
        .where(created_at: reporting_period)
        .where(spree_stores: { id: Spree::Store.current })
        .group('product_name', 'product_slug', 'spree_variants.sku')
        .select(
          'spree_product_translations.name as product_name',
          'spree_product_translations.slug as product_slug',
          'spree_variants.sku as sku',
          'count(spree_products.name) as additions',
          'sum(spree_cart_events.quantity) as quantity_change'
        )
    end
  end
end
