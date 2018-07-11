class Chat < ApplicationRecord
    belongs_to :user
    belongs_to :chat_room
    
    after_commit :chat_messege_notification, on: :create
    
    def chat_messege_notification
        Pusher.trigger("chat_room_#{self.chat_room_id}","chat", self.as_json)  # pusher 이벤트 발생시킴
    end
end
