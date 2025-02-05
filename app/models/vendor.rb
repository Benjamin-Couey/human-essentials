# == Schema Information
#
# Table name: vendors
#
#  id              :bigint           not null, primary key
#  address         :string
#  business_name   :string
#  comment         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

class Vendor < ApplicationRecord
  has_paper_trail
  include Provideable
  include Geocodable

  has_many :purchases, inverse_of: :vendor, dependent: :destroy

  validates :business_name, presence: true

  scope :alphabetized, -> { order(:business_name) }

  scope :with_volumes, -> {
    left_joins(purchases: :line_items)
      .select("vendors.*, SUM(COALESCE(line_items.quantity, 0)) AS volume")
      .group(:id)
  }
end
