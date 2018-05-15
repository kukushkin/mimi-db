class MyModel < Mimi::DB::Model
  field :id, as: :integer, primary_key: true, not_null: true, auto_increment: true

  field :name, as: :string, limit: 64
  field :code, as: :blob, default: -> { random_code }
  field :value, as: :decimal, precision: 10, scale: 3

  index :name

  def self.random_code
    SecureRandom.hex(16)
  end
end # class MyModel
