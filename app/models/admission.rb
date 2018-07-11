class Admission < ApplicationRecord
    belongs_to :user
    belongs_to :chat_room, counter_cache: true  #자동으로 admissions_count가 업데이트됨
    
    after_commit :user_join_chat_room_notification, on: :create # create action이 발생했을때(commit) 동작해라 
    after_commit :user_exit_chat_room_notification, on: :destroy
    
    def user_join_chat_room_notification
       Pusher.trigger("chat_room_#{self.chat_room_id}", 'join', self.as_json.merge({email: self.user.email})) # pusher로 보내줌
       Pusher.trigger("chat_room", "join", self.as_json) 
    end
    # chat_room을 고유하게 만들어주기 
    
    def user_exit_chat_room_notification
       Pusher.trigger("chat_room_#{self.chat_room_id}", 'exit', self.as_json.merge({email: self.user.email})) 
       Pusher.trigger("chat_room", "exit", self.as_json) 
    end
end
