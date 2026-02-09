class CreateAiGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_generations do |t|
      t.references :item, null: false, foreign_key: true
      t.string :field_name
      t.text :prompt_used
      t.text :result
      t.string :model_used
      t.integer :tokens_used

      t.timestamps
    end
  end
end
