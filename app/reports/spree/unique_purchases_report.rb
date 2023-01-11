# frozen_string_literal: true

module Spree
  # Unique Purchases Report
  class UniquePurchasesReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { sku: :string, product_name: :string, sold_count: :integer,
                                   users: :integer }.freeze
    SEARCH_ATTRIBUTES          = { start_date: :orders_completed_from,
                                   end_date: :orders_completed_till }.freeze
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :sold_count, :users].freeze

    deeplink product_name: {
      template: %(
        <a href="/#{I18n.locale}/admin/products/{%# o.product_slug %}" target="_blank">
        {%# o.product_name %}</a>
      )
    }

    class Result < Spree::Report::Result
      # Observation class
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :sku, :sold_count, :users]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      user_count_sql = '(COUNT(DISTINCT(spree_orders.email)))'
      purchases_by_variant =
        Spree::LineItem
          .joins(:order)
          .joins(:variant)
          .joins(product: :translations)
          .where(spree_orders: {
            state: 'complete',
            completed_at: reporting_period,
            store_id: Spree::Store.current
            }
          )
          .group(
            'variant_id',
            'spree_variants.sku',
            'spree_product_translations.slug',
            'spree_product_translations.name'
          )
          .select(
            'spree_variants.sku as sku',
            'spree_product_translations.slug as product_slug',
            'spree_product_translations.name as product_name',
            'SUM(quantity) as sold_count',
            "#{user_count_sql} as users"
          )
    end
  end
end
