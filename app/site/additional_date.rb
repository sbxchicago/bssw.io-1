class AdditionalDate < ApplicationRecord
  belongs_to :event

  include Dateable 
  
end
