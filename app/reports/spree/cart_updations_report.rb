# frozen_string_literal: true

module Spree
  # Cart Updations Report
  class CartUpdationsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { sku: :string, product_name: :string, updations: :integer,
                                   quantity_increase: :integer,
                                   quantity_decrease: :integer }.freeze
    SEARCH_ATTRIBUTES          = { start_date: :product_updated_from,
                                   end_date: :product_updated_to }.freeze
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :updations, :quantity_increase,
                                  :quantity_decrease].freeze

    deeplink product_name: {
      template: %(
        <a href="/#{I18n.locale}/admin/products/{%# o.product_slug %}" target="_blank">
        {%# o.product_name %}</a>
      )
    }

    class Result < Spree::Report::Result
      # Observation class
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :updations, :quantity_increase, :sku,
                            :quantity_decrease]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      quantity_increase_sql = 'CASE WHEN quantity > 0 then spree_cart_events.quantity ELSE 0 END'
      quantity_decrease_sql = 'CASE WHEN quantity < 0 then spree_cart_events.quantity ELSE 0 END'

      Spree::CartEvent
        .updated
        .joins(variant: { product: :translations })
        .joins(variant: { product: :stores })
        .where(created_at: reporting_period)
        .where(spree_stores: { id: Spree::Store.current })
        .group('product_name', 'product_slug', 'spree_variants.sku')
        .select(
          'spree_product_translations.name as product_name',
          'spree_product_translations.slug as product_slug',
          'spree_variants.sku as sku',
          'count(spree_product_translations.name) as updations',
          "SUM(#{quantity_increase_sql}) as quantity_increase",
          "SUM(#{quantity_decrease_sql}) as quantity_decrease"
        )
    end
  end
end
