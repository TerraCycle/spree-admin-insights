# frozen_string_literal: true

module Spree
  # Product Views To Purchases Report
  class ProductViewsToPurchasesReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { product_name: :string, views: :integer, purchases: :integer,
                                   purchase_to_view_ratio: :integer }.freeze
    SEARCH_ATTRIBUTES          = { start_date: :product_view_from,
                                   end_date: :product_view_till }.freeze
    SORTABLE_ATTRIBUTES        = [:product_name, :views, :purchases].freeze

    class Result < Spree::Report::Result
      # Observation class
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :views, :purchases,
                            :purchase_to_view_ratio]

        # This is inconsistent across postgres and mysql
        def purchase_to_view_ratio
          (purchases.to_f / views.to_f).round(2)
        end
      end
    end

    deeplink product_name: {
      template: %(
        <a href="/#{I18n.locale}/admin/products/{%# o.product_slug %}" target="_blank">
        {%# o.product_name %}</a>
      )
    }

    def report_query
      page_events_ar = Arel::Table.new(:spree_page_events)
      purchase_line_items_ar = Arel::Table.new(:purchase_line_items)

      Spree::Report::QueryFragments.from_subquery(purchase_line_items, as: :purchase_line_items)
        .join(page_events_ar)
        .on(page_events_ar[:target_id].eq(purchase_line_items_ar[:product_id]))
        .where(page_events_ar[:target_type].eq(Arel::Nodes::Quoted.new('Spree::Product')))
        .where(page_events_ar[:activity].eq(Arel::Nodes::Quoted.new('view')))
        .group(purchase_line_items_ar[:product_id], purchase_line_items_ar[:product_name],
               purchase_line_items_ar[:product_slug], purchase_line_items_ar[:purchases])
        .project(
          'product_name',
          'product_slug',
          'COUNT(*) as views',
          'purchases'
        )
    end

    private

    def purchase_line_items
      Spree::LineItem
        .joins(:order)
        .joins(:variant)
        .joins(product: :translations)
        .where(spree_orders: {
          state: 'complete',
          created_at: reporting_period,
          store_id: Spree::Store.current
          }
        )
        .group('spree_products.id', 'spree_product_translations.name')
        .select(
          'SUM(quantity) as purchases',
          'spree_product_translations.name as product_name',
          'spree_product_translations.slug as product_slug',
          'spree_products.id as product_id'
        )
    end
  end
end
