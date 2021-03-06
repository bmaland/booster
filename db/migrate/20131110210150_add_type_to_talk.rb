class AddTypeToTalk < ActiveRecord::Migration
  def change
    add_column :talks, :type, :string

    Talk.all.each do |talk|
      if talk.is_tutorial?
        talk.type = Workshop.to_s
      elsif talk.is_lightning_talk?
        talk.type = LightningTalk.to_s
      else
        talk.type = Keynote.to_s
      end

      talk.save
    end
  end
end
